-- Actual Edit Mode/widget owners; desktop ownership/dispatch, not a native taint VM.
local function read(path)
    local f=assert(io.open(path,"rb"));local s=f:read("*a"):gsub("\r\n","\n");f:close();return s
end
local ui=read(arg[1] or "Core/FluxAPI/UI.lua")
local tooltip=read(arg[2] or "Other/FluxHUDTooltip.lua")
local debugSource=read(arg[3] or "Other/FluxInputDebug.lua")
local function slice(s,a,b)local i=assert(s:find(a,1,true),a);return s:sub(i,assert(s:find(b,i+#a,true),b)-1)end
local helpers=slice(ui,"function FluxSecureUIPanelsBlockInsecureWork()","-- Micro menu helpers")
local checks,failures=0,0
local function check(v,why)checks=checks+1;if not v then failures=failures+1;print("FAIL "..why)end end
local function method(text,owner,name)
    return assert(text:match("function "..owner..":"..name.."%([^)]*%)\n.-\nend"),owner..":"..name)
end
for _,branch in ipairs({"live","forever","classic","classic_era","classic_anniversary"})do
    local ref="../__AddonsForRef/wow-ui-source-"..branch.."/Interface/AddOns/"
    local native=read(ref.."Blizzard_EditMode/Shared/EditModeSystemTemplates.lua")
    local managerSource=read(ref.."Blizzard_EditMode/Shared/EditModeManager.lua")
    local callbacks,timers,watchers,hooks={},{},{},{}
    local combat,playerOwned,petOwned,targetOwned,focusOwned=false,false,false,false,false
    local counts={base=0,override=0,unregister=0,flags=0,nativeSave=0,nativeParty=0}
    local ns={Flux={Bars={secureReady=true,Stance={secureReady=true}},Combat={}}}
    local e=setmetatable({FLUX_API={hasEditMode=true},EditModeSystemMixin={},EditModeManagerFrameMixin={}}, {__index=_G});e._G=e
    local function run(s,name)return assert(load(s,"@"..(name or "production-edit-mode"),"t",e))("_FluxUI",ns)end
    for _,m in ipairs({"SetPointOverride","ClearAllPointsOverride","SetSnappedToFrame","ClearFrameSnap","PrepareForSave"})do
        run(method(native,"EditModeSystemMixin",m))
    end
    for _,m in ipairs({"OnEditModeSystemAnchorChanged","SaveLayouts","PrepareSystemsForSave","EnterEditMode","ExitEditMode","IsEditModeActive","IsEditModeLocked"})do
        local prefix=m=="PrepareSystemsForSave"and assert(managerSource:match("local function callPrepareForSave%([^)]*%)\n.-\nend")).."\n"or ""
        run(prefix..method(managerSource,"EditModeManagerFrameMixin",m))
    end
    local function widget(owned)
        local w={alpha=0.65,click=true,motion=false,shown=true,events={},scripts={},owned=owned}
        function w:GetAlpha()return self.alpha end
        function w:SetAlpha(v)self.alpha=v end
        function w:IsMouseEnabled()return self.click or self.motion end
        function w:EnableMouse(v)self.click,self.motion=v,v end
        function w:IsMouseClickEnabled()return self.click end
        function w:IsMouseMotionEnabled()return self.motion end
        function w:SetMouseClickEnabled(v)self.click=v end
        function w:SetMouseMotionEnabled(v)self.motion=v end
        function w:IsShown()return self.shown end
        function w:IsVisible()return self.shown end
        function w:RegisterEvent(v)self.events[v]=true end
        function w:IsEventRegistered(v)return self.events[v]~=nil end
        function w:UnregisterEvent(v)
            if not self.owned and v=="PLAYER_SPECIALIZATION_CHANGED"then counts.unregister=counts.unregister+1 end
            self.events[v]=nil
        end
        function w:SetScript(k,fn)check(self.owned,"native scripts untouched");self.scripts[k]=fn end
        function w:SetMovable(v)counts.flags=counts.flags+1;self.movable=v end
        function w:IsMovable()return self.movable end
        function w:SetUserPlaced(v)counts.flags=counts.flags+1;self.userPlaced=v end
        function w:ClearAllPointsBase()counts.base=counts.base+1;self.point=nil end
        function w:SetPointBase(...)counts.base=counts.base+1;self.point={...}end
        function w:SetOwner(owner,anchor)self.owner,self.ownerAnchor=owner,anchor end
        function w:IsForbidden()return false end
        return w
    end
    local function system()
        local w=widget(false)
        for k,v in pairs(e.EditModeSystemMixin)do w[k]=v end
        w.SetPoint=function(self,...)counts.override=counts.override+1;return e.EditModeSystemMixin.SetPointOverride(self,...)end
        w.ClearAllPoints=function(self,...)counts.override=counts.override+1;return e.EditModeSystemMixin.ClearAllPointsOverride(self,...)end
        w.IsInDefaultPosition=function()return true end
        w.Selection,w.EditModeResizeButton=widget(false),widget(false)
        w.systemInfo={anchorInfo={point="TOPRIGHT"},isInDefaultPosition=true}
        return w
    end
    e.UIParent=widget(false)
    local manager=widget(false)
    for k,v in pairs(e.EditModeManagerFrameMixin)do manager[k]=v end
    manager.shown=false
    manager.events.PLAYER_SPECIALIZATION_CHANGED={"player"}
    local originalSpec=manager.events.PLAYER_SPECIALIZATION_CHANGED
    manager.layoutInfo={activeLayout=2,layouts={{layoutName="Player custom layout",systems={}}}}
    local originalLayout=manager.layoutInfo
    manager.registeredSystemFrames={}
    local noop=function()end
    e.PlaySound,e.SOUNDKIT=noop,{}
    for _,name in ipairs({"ClearActiveChangesFlags","UpdateDropdownOptions","ShowSystemSelections","RevertAllChanges",
        "HideSystemSelections","InvokeOnAnyEditModeSystemAnchorChanged"})do manager[name]=noop end
    manager.AccountSettings={OnEditModeEnter=noop,OnEditModeExit=function()counts.nativeParty=counts.nativeParty+1 end}
    e.EditModeManagerFrame=manager
    e.C_UnitAuras={SwitchAuraDataProvider=noop,ResetAuraDataProvider=noop}
    e.C_EditMode={OnEditModeExit=noop,SaveLayouts=function(info)
        check(info==originalLayout,"native save retains exact layout object");counts.nativeSave=counts.nativeSave+1
    end}
    e.secureexecuterange=function(t,fn,...)for k,v in pairs(t)do fn(k,v,...)end end
    e.EventRegistry={
        RegisterCallback=function(_,name,fn)callbacks[name]=callbacks[name]or{};table.insert(callbacks[name],fn)end,
        TriggerEvent=function(_,name,...)for _,fn in ipairs(callbacks[name]or{})do fn(...)end end,
    }
    e.C_Timer={After=function(_,fn)timers[#timers+1]=fn end}
    e.InCombatLockdown=function()return combat end
    e.CreateFrame=function()local w=widget(true);watchers[#watchers+1]=w;return w end
    e.FluxUnitFrames_ShouldUseFlux=function(unit)return unit=="player"and playerOwned or unit=="pet"and petOwned or unit=="target"and targetOwned or unit=="focus"and focusOwned or false end
    local deferred={}
    ns.Flux.Combat.Defer=function(k,fn)deferred[k]=fn end
    e.hooksecurefunc=function(name,fn)hooks[name]=fn end
    e.GameTooltip_SetDefaultAnchor=noop
    e.GameTooltipDefaultContainer=system()
    e.GameTooltip=widget(false);e.GameTooltip.SetPoint=e.GameTooltip.SetPointBase;e.GameTooltip.ClearAllPoints=e.GameTooltip.ClearAllPointsBase
    e.GameTooltip.SetPointBase,e.GameTooltip.ClearAllPointsBase=nil,nil
    e.PlayerFrame,e.PetFrame,e.PlayerCastingBarFrame=system(),system(),system()
    e.TargetFrame,e.FocusFrame=system(),system()
    e.BuffIconCooldownViewer,e.EssentialCooldownViewer,e.CompactPartyFrame=system(),system(),system()
    local privateReads=0
    e.BuffIconCooldownViewer.auraInstanceIDToItemFramesMap=setmetatable({}, {__index=function()privateReads=privateReads+1;error("private viewer map accessed")end})
    e.FluxWindowFrame={GetFrame=function()return e.UIParent end}
    manager.registeredSystemFrames={e.GameTooltipDefaultContainer,e.BuffIconCooldownViewer,e.CompactPartyFrame}
    run("local _,ns=...;local _issecretvalue=issecretvalue\n"..helpers,"production-edit-helpers")
    run(tooltip,"production-HUD-tooltip")
    local function flush()
        local q=timers;timers={};for _,fn in ipairs(q)do fn()end
    end
    local function login()
        for _,w in ipairs(watchers)do if w.events.PLAYER_LOGIN then w.scripts.OnEvent(w,"PLAYER_LOGIN")end end
        flush();flush()
    end
    login()
    check(counts.unregister==0 and manager.events.PLAYER_SPECIALIZATION_CHANGED==originalSpec,branch.." native spec event/filter retained")
    check(counts.override==0 and manager.editModeSystemAnchorDirty==nil,branch.." Flux tooltip never writes native anchor state")
    check(counts.flags==0,branch.." native movable/user-placed flags retained")
    local function shownChrome(frame,label)
        check(frame.Selection.alpha==0.65 and frame.Selection.click and not frame.Selection.motion,branch.." "..label.." native selector unchanged")
    end
    shownChrome(e.PlayerFrame,"player off");shownChrome(e.PetFrame,"pet off");shownChrome(e.PlayerCastingBarFrame,"cast off")
    shownChrome(e.TargetFrame,"target off");shownChrome(e.FocusFrame,"focus off")
    shownChrome(e.BuffIconCooldownViewer,"viewer");shownChrome(e.CompactPartyFrame,"party")
    for cycle=1,3 do
        local before=counts.base
        manager.shown=true;manager:EnterEditMode();flush()
        check(counts.base==before,branch.." entering editor does not redock native frames")
        for _=1,20 do
            hooks.GameTooltip_SetDefaultAnchor(e.GameTooltipDefaultContainer,e.UIParent)
            ns.ApplyHUDTooltipPosition(e.GameTooltipDefaultContainer)
        end
        check(counts.base==before,branch.." editor tooltip bursts do not move native frames")
        -- Native dialogs hide the manager temporarily while active/locked.
        manager.shown=false;manager.editModeLockState="hideSelections"
        ns.ApplyHUDTooltipPosition(e.GameTooltipDefaultContainer);flush()
        check(counts.base==before,branch.." temporary editor dialog owns its layout")
        manager.editModeLockState=nil;manager.shown=true
        manager:SaveLayouts()
        check(manager.layoutInfo==originalLayout and originalLayout.layouts[1].layoutName=="Player custom layout",branch.." layout data preserved on save")
        manager.shown=false;manager:ExitEditMode()
        check(counts.base==before,branch.." native close stack performs no Flux layout")
        flush();flush()
        check(counts.base>before,branch.." tooltip docking restored after exit")
        local point=e.GameTooltipDefaultContainer.point
        check(point and point[1]=="BOTTOMLEFT"and point[2]==e.UIParent and point[3]=="TOPLEFT"and point[4]==0 and point[5]==30,branch.." exact tooltip geometry retained")
    end
    check(counts.nativeSave==3 and counts.nativeParty==3,branch.." native save and party reset remain available")
    check(counts.override==0 and manager.editModeSystemAnchorDirty==nil,branch.." repeated saves do not taint modeled anchor ownership")
    playerOwned,petOwned,targetOwned,focusOwned=true,true,true,true
    manager.shown=true;manager:EnterEditMode();flush()
    check(e.PlayerFrame.Selection.alpha==0 and not e.PlayerFrame.Selection.click,branch.." replaced player selector muted")
    check(e.PetFrame.Selection.alpha==0 and not e.PetFrame.Selection.click,branch.." replaced pet selector muted")
    check(e.TargetFrame.Selection.alpha==0 and not e.TargetFrame.Selection.click,branch.." replaced target selector muted")
    check(e.FocusFrame.Selection.alpha==0 and not e.FocusFrame.Selection.click,branch.." replaced focus selector muted")
    manager.shown=false;manager:ExitEditMode();flush()
    playerOwned,petOwned,targetOwned,focusOwned=false,false,false,false
    manager.shown=true;manager:EnterEditMode();flush()
    shownChrome(e.PlayerFrame,"restored player");shownChrome(e.PetFrame,"restored pet");shownChrome(e.PlayerCastingBarFrame,"restored cast")
    shownChrome(e.TargetFrame,"restored target");shownChrome(e.FocusFrame,"restored focus")
    shownChrome(e.BuffIconCooldownViewer,"viewer after saves");shownChrome(e.CompactPartyFrame,"party after saves")
    manager.shown=false;manager:ExitEditMode();flush()
    combat=true
    local before=counts.base
    ns.ApplyHUDTooltipPosition(e.GameTooltipDefaultContainer)
    check(counts.base==before,branch.." native system container waits in combat")
    ns.SetHUDTooltipOwner(e.GameTooltip,e.UIParent)
    check(e.GameTooltip.owner==e.UIParent and e.GameTooltip.point and e.GameTooltip.point[5]==30,branch.." ordinary combat tooltip remains usable")
    combat=false;for _,fn in pairs(deferred)do fn()end
    check(e.GameTooltipDefaultContainer.point[5]==30,branch.." deferred container position retained")
    e.SlashCmdList={}
    e.issecurevariable=function(object,key)
        if object==e.BuffIconCooldownViewer and key=="auraInstanceIDToItemFramesMap"then return false,"_FluxUI"end
        return true
    end
    e.FluxPerfCaptureDB={inputDebug={sentinel=true},oldEvidence={keep=true}}
    run(debugSource,"production-input-debug")
    local debug=ns.Flux.InputDebug
    check(type(debug.CaptureEditMode)=="function",branch.." optional Edit Mode metadata capture available")
    if debug.CaptureEditMode then
        local beforeFrames,beforeTimers=#watchers,#timers
        for i=1,4 do e.SlashCmdList.FLUXINPUT("edit")end
        local saved=e.FluxPerfCaptureDB.editModeDebug
        check(saved.latest.complete and saved.previous.complete and saved.previous.previous==nil,branch.." optional capture bounded to two samples")
        check(saved.latest.nativeSpecEvent==true,branch.." diagnostic observes preserved native spec event")
        check(e.FluxPerfCaptureDB.inputDebug.sentinel and e.FluxPerfCaptureDB.oldEvidence.keep,branch.." prior diagnostic roots retained")
        check(not saved.latest.frames.BuffIconCooldownViewer.security.auraInstanceIDToItemFramesMap.secure,branch.." private map field metadata recorded without reading contents")
        check(#watchers==beforeFrames and #timers==beforeTimers,branch.." metadata capture creates no frames or timers")
    end
    check(privateReads==0,branch.." private Cooldown Viewer tables never inspected")
    print(("Edit Mode resources %s: base=%d overrides=%d nativeSpecUnregister=%d flags=%d saves=%d resets=%d"):format(branch,counts.base,counts.override,counts.unregister,counts.flags,counts.nativeSave,counts.nativeParty))
end
print(("Edit Mode native ownership: %d checks; %d failures; native protected execution/taint/pixels pending"):format(checks,failures))
assert(failures==0,"Edit Mode ownership regression")

