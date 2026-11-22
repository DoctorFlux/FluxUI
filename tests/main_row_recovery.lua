-- Actual Init/State/Layout/Clicks owners and Blizzard's native slot calculator.
-- Widget transport is modeled; no native secure VM or gameplay-content recovery claim.
local checks=0
local function check(ok,msg)checks=checks+1;assert(ok,msg)end
local function read(path)local f=assert(io.open(path,"rb"));local s=f:read("*a"):gsub("\r\n","\n");f:close();return s end
local native=read("../__AddonsForRef/wow-ui-source-forever/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua")
local function nativeFunction(signature,replacement,e)
    local a=assert(native:find(signature,1,true));local b=assert(native:find("\nend",a,true))+3
    return assert(load(replacement..native:sub(a+#signature,b),"native main-row method","t",e))()
end
local pageTwoSlots = { 1, 2, 3, 4, 5, 6, 7, 20, 21, 22, 23, 24, 13, 14, 15, 16, 17, 18, 19 }
local function mainSlot(column, page, swap)
    if column > 12 then return column + (swap == 1 and 36 or swap == 2 and 24 or 0) end
    if swap ~= 0 and page < 11 then return column + (swap == 1 and 60 or 24) end
    if page == 2 then return pageTwoSlots[column] end
    return (page - 1) * 12 + column
end
for _,securePaging in ipairs({false,true})do
for _,family in ipairs({"retail","forever","classic","era","anniversary"})do
    local writes,clearKeys,painted,cleared,bindingsNotified=0,0,0,0,0
    local flux={Client={isForever=family=="forever",isCamelot=family=="forever"},Module={Register=function()end}}
    local e=setmetatable({SlashCmdList={},unpack=table.unpack},{__index=_G});e._G=e
    local log={};e.print=function(s)log[#log+1]=s end;flux.Print=e.print
    e.InCombatLockdown=function()return e.locked end
    flux.Combat={InLockdown=e.InCombatLockdown}
    e.IsShiftKeyDown=function()return e.shift end;e.IsControlKeyDown=function()return e.ctrl end
    e.GetCVarBool=function()return false end
    e.SECURE_ACTIONS={};e.ATTRIBUTE_NOOP={}
    e.C_ActionBar={GetActionBarPage=function()return 1 end}
    e.NUM_ACTIONBAR_BUTTONS=12
    local m={}
    function m:GetAttribute(a,b,c)
        if b then return self.attrs[a..b..c] or self.attrs["*"..b..c] or self.attrs[a..b.."*"] or self.attrs["*"..b.."*"] or self.attrs[b]end
        return self.attrs[a]
    end
    local secure=false
    local function run(self,body,args)
        local context=setmetatable({self=self,control=self},{__index=e})
        for k,v in pairs(args or {})do context[k]=v end
        return assert(load(body,"modeled paging transport","t",context))()
    end
    function m:SetAttribute(k,v)
        assert(not e.locked or secure,"protected metadata writes stay in secure transport during combat")
        writes=writes+1;local changed=self.attrs[k]~=v;self.attrs[k]=v
        -- Model native attribute dispatch to the installed host index consumer.
        -- The game's taint/attribute-event engine is not reproduced here.
        if changed and k=="action" and self._fluxHost then flux.Bars.Hosts.IndexSlot(self._fluxHost,v)end
        local state=k:match("^state%-(.+)$")
        if changed and state and self.attrs["_onstate-"..state]then
            run(self,self.attrs["_onstate-"..state],{stateid=state,newstate=v})
        end
    end
    function m:SetID(id)assert(not e.locked,"ID writes stay out of combat");writes=writes+1;self.id=id end
    function m:GetID()return self.id end
    function m:SetParent(p)
        assert(not e.locked,"parent writes stay out of combat");writes=writes+1
        if self.parent then self.parent.children[self]=nil end
        self.parent=p;if p then p.children[self]=true end
    end
    function m:GetParent()return self.parent end
    function m:GetName()return self.name end
    function m:RegisterForClicks(...)self.clicks={...}end
    function m:Hide()end
    function m:SetSize()end
    function m:EnableMouse()end
    function m:Show()end
    function m:SetFrameLevel()end
    function m:GetFrameLevel()return 1 end
    function m:SetFrameRef(name,value)self.refs[name]=value end
    function m:GetFrameRef(name)return self.refs[name]end
    function m:RunAttribute(name)local body=assert(self.attrs[name],name);return run(self,body)end
    function m:Execute(body)
        assert(not e.locked,"insecure header execution stays out of combat")
        local before=secure;secure=true;local result=run(self,body);secure=before;return result
    end
    function m:ChildUpdate(name,message)
        for child in pairs(self.children)do
            local body=child.attrs["_childupdate-"..name]
            if body then run(child,body,{message=message,control=self})end
        end
    end
    local function frame(name,parent)
        local f=setmetatable({attrs={},id=0,name=name,children={},refs={}},{__index=m})
        if parent then f:SetParent(parent)end;if name then e[name]=f end;return f
    end
    e.LOCAL_CHECK_Frame={GetAttribute=m.GetAttribute,GetParent=m.GetParent}
    e.SecureButton_GetModifierPrefix=function()return e.shift and "shift-" or e.ctrl and "ctrl-" or ""end
    e.SecureButton_GetButtonSuffix=function(button)return button=="LeftButton" and "1" or button end
    e.SecureButton_GetEffectiveButton=function()return "LeftButton"end
    e.SecureButton_GetModifiedAttribute=nativeFunction("function SecureButton_GetModifiedAttribute(frame, name, button, prefix, suffix)","return function(frame,name,button,prefix,suffix)",e)
    m.CalculateAction=nativeFunction("function SecureActionButtonMixin:CalculateAction(button)","return function(self,button)",e)
    flux.Restricted={PagingWorks=function()return securePaging end,
        SetPagingSnippet=function(f,k,v)f:SetAttribute(k,v);return true end,
        RegisterPagingDriver=function(f,name)
            f:SetAttribute("state-"..name,name=="native" and "1" or "0");return true
        end,
        UnregisterPagingDriver=function()return true end,
        ExecutePaging=function(f,body)return f:Execute(body)end}
    flux.ButtonFX={Click={UsesWrap=function()return family~="forever"end}}
    flux.Action={HasAction=function()return true end}
    e.CreateFrame=function(_,name,parent)return frame(name,parent)end
    e.UnitClass=function()return "Priest","PRIEST"end
    e.IsPressHoldReleaseSpell=function()return false end
    e.GetActionInfo=function(slot)return "spell",1000+slot end
    for _,name in ipairs({"PlaceAction","PickupAction","ClearCursor","SaveBindings","LoadBindings","SetBinding"})do
        e[name]=function()error("recovery changed player action contents/preferences: "..name)end
    end
    for _,path in ipairs({"Bars/Init.lua","Bars/SlotMath.lua","Bars/State.lua","Bars/Hosts.lua","Bars/Layout.lua","Bars/Clicks.lua"})do
        assert(loadfile(path,"t",e))("_FluxUI",{Flux=flux})
    end
    local bars=flux.Bars;bars.started=true
    bars.Strip={frame=frame("strip")}
    bars.State.headers={main=frame("main"),sec=frame("sec"),tert=frame("tert"),staticMain=frame("staticMain"),staticSec=frame("staticSec"),staticTert=frame("staticTert")}
    bars.State.headers.main.attrs.actionpage=1
    if securePaging then
        check(bars.State.RegisterDrivers(),family..": actual secure header snippets installed")
        check(bars.State.UsesSecurePaging(),family..": recovery uses secure paging branch")
    end
    bars.Layout.IsExpanding=function()return false end
    local commands,rawBindings,overrides={},{},{}
    for column=1,19 do
        local col={};bars.hosts[column]=col
        for _,row in ipairs({"main","sec","tert"})do
            local w=frame("FluxActionStrip"..row..column)
            bars.State.Attach(bars.State.HeaderFor(column,row),w,column,row)
            col[row]={widget=w,column=column,row=row,slot=column,bindingCommand=bars.Hosts.BindingCommand(column)}
            w._fluxHost=col[row]
        end
        local proxy=frame("FluxActionStripKey"..column,col.main.widget)
        proxy._fluxKeyerReady=true
        for _,name in ipairs({"action","type","typerelease","macrotext","clickbutton","unit","checkmouseovercast"})do
            proxy.attrs["useparent-"..name]=true
        end
        commands[col.main.bindingCommand]=column==18 and "X" or column==19 and "C" or "KEY"..column
        rawBindings[commands[col.main.bindingCommand]]=col.main.bindingCommand
    end
    e.CreateFrame=function()error("recovery must reuse every existing surface")end
    e.GetBindingKey=function(cmd)return commands[cmd]end
    e.ClearOverrideBindings=function()clearKeys=clearKeys+1;overrides={}end
    e.SetOverrideBindingClick=function(_,_,key,target,button)overrides[key]={target,button}end
    bars.Paint={ClearCache=function()cleared=cleared+1 end,Flush=function()painted=painted+1 end}
    e.FluxBinding={NotifyBarReady=function(reason)
        check(reason=="main-row-restore" and clearKeys>0,"conditional binding owner notified after native key rebuild")
        bindingsNotified=bindingsNotified+1
    end}
    -- Prime the real mapping cache, then corrupt metadata while it still says
    -- these same occupancy flags are installed. Recovery must invalidate it.
    bars.Layout.ApplyMappings()
    check(bars.Clicks.RefreshKeys(),"initial override signature is populated")
    local initialClears=clearKeys
    overrides.X={"wrong-column","LeftButton"}
    local body="/cast [@mouseover,help] ExampleSpell"
    bars.hosts[19].main.widget.attrs["flux-p-19"]=body
    for column=1,19 do
        local h=bars.hosts[column].main;h.column=1;h.row="sec";h.slot=999
        h.widget.id=column+100;h.widget:SetParent(bars.State.headers.tert)
        h.widget.attrs["flux-column"]=1;h.widget.attrs["flux-static"]=0
        h.widget.attrs["flux-has-sec"]=0;h.widget.attrs["flux-has-tert"]=0
        h.widget.attrs.action1=6;h.widget.attrs["*action1"]=6
        h.widget.attrs["shift-action1"]=6;h.widget.attrs["ctrl-action1"]=6
        e["FluxActionStripKey"..column].id=77
        e["FluxActionStripKey"..column].attrs.action=6
        e["FluxActionStripKey"..column].attrs.action1=6
    end
    local before=writes;e.locked=true
    check(bars.RestoreMainRow()==false and writes==before,family..": combat prevents partial recovery")
    e.locked=false;e.shift=true
    check(bars.RestoreMainRow()==false and writes==before,family..": modifier guard prevents partial recovery")
    e.shift=false;local last=bars.hosts[19];bars.hosts[19]=nil
    check(bars.RestoreMainRow()==false and writes==before,family..": preflight checks the complete row")
    bars.hosts[19]=last
    check(bars.RestoreMainRow(),family..": complete main row recovery succeeds")
    for column=1,19 do
        local h=bars.hosts[column].main;local w=h.widget
        check(h.column==column and h.row=="main",family..": logical main identity restored")
        check(w:GetParent()==bars.State.HeaderFor(column,"main") and w:GetID()==0,family..": correct dynamic/static parent and zero native ID")
        check(w:GetAttribute("flux-static")== (column>12 and 1 or 0),family..": columns13-19 stay static")
        check(w:GetAttribute("flux-has-sec")==1 and w:GetAttribute("flux-has-tert")==1,family..": cached occupancy rebuilt")
        check(h.slot==column and w:GetAttribute("action")==column and w:CalculateAction("LeftButton")==column,
            family..": documented main "..column.." host="..tostring(h.slot).." action="..tostring(w:GetAttribute("action")).." click="..tostring(w:CalculateAction("LeftButton")).." secure="..tostring(securePaging))
        local key=commands[h.bindingCommand];local target=overrides[key]
        local expected=family=="forever" and "FluxActionStripKey"..column or w:GetName()
        check(target and target[1]==expected,family..": key targets the correct column")
        if family=="forever" then
            check(e[expected]:GetID()==0 and e[expected]:CalculateAction("LeftButton")==column,"Forever key proxy owns matching restored main slot")
        end
        check(rawBindings[key]==h.bindingCommand,family..": player's raw keybinding preserved")
    end
    check(last.main.widget:GetAttribute("flux-p-19")==body and last.main.widget:GetAttribute("type")=="macro",family..": stored slot program survives routing rebuild")
    check(clearKeys==initialClears+1 and cleared==19 and painted==1,family..": one override rebuild and one main-row repaint")
    check(bindingsNotified==1,family..": existing binding-profile owner reuses its normal apply path")
    check(bars.RestoreMainRow(),family..": repeated restore is safe")
    for column=1,19 do
        local h=bars.hosts[column].main
        check(h.slot==column and h.widget:CalculateAction("LeftButton")==column,family..": repeated restore preserves all main slots")
    end
    -- Page 2 shares native slots with the fixed columns. The fixed columns keep
    -- those actions while the first seven native columns keep their base slots.
    for _,page in ipairs({1,2,6,7,9,11,12})do
        bars.State.headers.main.attrs.actionpage=page
        if securePaging then
            for _,header in ipairs({bars.State.headers.main,bars.State.headers.sec,bars.State.headers.tert})do
                header:SetAttribute("state-native",tostring(page))
            end
        end
        for swap=0,2 do
            e.shift,e.ctrl=swap==1,swap==2
            if securePaging then bars.State.hub:SetAttribute("state-mod",tostring(swap))end
            check(bars.State.ForceApply(),family..": real state owner reapplies page/modifier")
            for column=1,19 do
                local expected=mainSlot(column,page,swap)
                local host=bars.hosts[column].main
                check(host.slot==expected and host.widget:CalculateAction("LeftButton")==expected,
                    family..": main-row resolution for page "..page..", modifier "..swap..", column "..column)
                if family=="forever"then check(e["FluxActionStripKey"..column]:CalculateAction("LeftButton")==expected,"Forever key and mouse agree across page/modifier states")end
            end
        end
    end
    -- The recovery must retain normal promotion rather than forcing empty
    -- fixed columns back to their empty main slots. Exercise both/one/no minis.
    local function state(page,swap)
        e.shift,e.ctrl=swap==1,swap==2
        if securePaging then
            local previous=secure;secure=true
            for _,header in ipairs({bars.State.headers.main,bars.State.headers.sec,bars.State.headers.tert})do
                header:SetAttribute("state-native",tostring(page))
            end
            bars.State.hub:SetAttribute("state-mod",tostring(swap));secure=previous
        else bars.State.headers.main.attrs.actionpage=page end
        if e.locked then
            check(bars.State.ForceApply()==false,"insecure force-apply never enters locked secure transport")
            bars.State.IndexLiveSlots()
        else check(bars.State.ForceApply(),"actual state owner applies test state")end
    end
    state(2,0)
    check(bars.RestoreMainRow(),family..": restore preserves an ordinary active page")
    check(bars.State.GetCurrentPage()==2,family..": native page selection remains on page 2")
    local seen={}
    for column=1,19 do
        local expected=pageTwoSlots[column]
        local host=bars.hosts[column].main
        local slot=host.widget:CalculateAction("LeftButton")
        check(host.slot==expected and slot==expected,"restore preserves page 2's accessible slots and the fixed columns")
        check(not seen[slot],"page 2 has one visible main button for each occupied action slot")
        seen[slot]=true
    end
    state(1,0)
    for _,missing in ipairs({{[18]=true},{[18]=true,[54]=true},{[18]=true,[54]=true,[42]=true},{}})do
        flux.Action.HasAction=function(slot)return not missing[slot]end
        e.HasAction=flux.Action.HasAction
        check(bars.RestoreMainRow(),family..": restore recalculates fixed-column promotion")
        for swap=0,2 do
            state(1,swap)
            local expected=not missing[18] and (swap==1 and 54 or swap==2 and 42 or 18)
                or not missing[54] and (swap==0 and 54 or 42)
                or not missing[42] and 42 or 18
            local host=bars.hosts[18].main
            check(host.slot==expected and host.widget:CalculateAction("LeftButton")==expected,"fixed18 native action follows actual promotion")
            if family=="forever"then check(e.FluxActionStripKey18:CalculateAction("LeftButton")==expected,"fixed18 promoted key/mouse routes agree")end
        end
        state(1,0)
    end
    if securePaging then
        -- Actual header/ChildUpdate bodies run in modeled secure transport;
        -- only the simulated engine can advance native state while locked.
        e.locked=true
        for _,page in ipairs({1,2,7,11,12,1})do
            for swap=0,2 do
                state(page,swap)
                for column=1,19 do
                    local expected=mainSlot(column,page,swap)
                    local host=bars.hosts[column].main
                    check(host.slot==expected and host.widget:CalculateAction("LeftButton")==expected,"secure restored row follows combat page/modifier transition")
                    if family=="forever"then check(e["FluxActionStripKey"..column]:CalculateAction("LeftButton")==expected,"secure restored key matches mouse during combat state change")end
                end
            end
        end
        state(1,0)
        local overlay=bars.hosts[19].main.widget
        check(overlay:GetAttribute("flux-p-19")==body,"slot program retained through secure transitions")
        check(e.SecureButton_GetModifiedAttribute(overlay,"type","LeftButton")=="macro"
            and e.SecureButton_GetModifiedAttribute(overlay,"macrotext","LeftButton")==body,
            "restored slot19 overlay resumes its native macro selectors")
        if family=="forever"then
            check(e.SecureButton_GetModifiedAttribute(e.FluxActionStripKey19,"type","LeftButton")=="macro"
                and e.SecureButton_GetModifiedAttribute(e.FluxActionStripKey19,"macrotext","LeftButton")==body,
                "Forever key proxy owns restored slot19 overlay")
        end
        e.locked=false
    end
end
end
print(("Main-row recovery: %d checks PASS across five client models and fallback/secure-header paths; actual state/layout/click owners and native slot calculator; modeled secure transport, in-game acceptance pending"):format(checks))
