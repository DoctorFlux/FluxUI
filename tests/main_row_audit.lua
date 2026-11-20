-- Real audit command; native getters are mocked, protected writes are forbidden.
local checks=0
local function check(v,msg)checks=checks+1;assert(v,msg)end
for _,family in ipairs({"retail","forever","classic","era","anniversary"})do
    local lines,reads={},0
    local private={}
    local flux={Client={branch=family},Module={Register=function()end}}
    local e=setmetatable({SlashCmdList={}},{__index=_G});e._G=e
    e.print=function(s)lines[#lines+1]=s end;flux.Print=e.print
    e.InCombatLockdown=function()return e.locked end
    flux.Combat={InLockdown=e.InCombatLockdown}
    e.IsShiftKeyDown=function()return e.shift end
    e.IsControlKeyDown=function()return false end
    e.issecretvalue=function(v)return v==private end
    for _,name in ipairs({"CreateFrame","SetOverrideBindingClick","PlaceAction","PickupAction","ClearCursor"})do
        e[name]=function()error("read-only audit attempted "..name)end
    end
    assert(loadfile("Bars/Init.lua","t",e))("_FluxUI",{Flux=flux})
    assert(loadfile("Bars/SlotMath.lua","t",e))("_FluxUI",{Flux=flux})
    local bars=flux.Bars
    bars.State={GetCurrentPage=function()return e.page or 1 end}
    flux.Action={GetInfo=function(slot)reads=reads+1;return "spell",e.secret and private or 1000+slot end,
        GetTexture=function(slot)return 2000+slot end}
    flux.Spell={GetName=function(id)check(id~=private,"private spell ID never passed to name lookup");return "Spell"..id end}
    e.GetBindingKey=function(cmd)return cmd=="cmd18" and "X" or cmd=="cmd19" and "C" or cmd end
    e.GetBindingAction=function(key,overrides)check(overrides==true,"audit checks effective overrides");return "CLICK route-"..key end
    for i=1,19 do
        local slot=i
        local w={attrs={action=i,["flux-promoted"]=0,["flux-has-sec"]=0,["flux-has-tert"]=0}}
        function w:GetAttribute(k)return self.attrs[k]end
        function w:CalculateAction(button)check(button=="LeftButton","mouse uses real native LeftButton calculation");return slot==18 and 6 or slot end
        function w:SetAttribute()error("audit wrote action attributes")end
        function w:SetID()error("audit wrote button IDs")end
        bars.hosts[i]={main={widget=w,slot=i,bindingCommand="cmd"..i,WIcon={GetTexture=function()return 4000+slot end}}}
        e["FluxActionStripKey"..i]={CalculateAction=function(_,button)check(button=="LeftButton","proxy uses native LeftButton calculation");return slot end}
    end
    e.SlashCmdList.FLUXBARS("audit")
    check(#lines==20 and reads==19,family..": one header and all19main surfaces")
    check(lines[19]:find("18 expected=18 host=18 attr=18 click=6 keyClick=18 key=X",1,true),family..": exposes effective mouse mismatch hidden by matching attributes")
    check(lines[19]:find("action=spell/1018 Spell1018",1,true) and lines[19]:find("icon=4018/2018",1,true),family..": action identity and shown/native texture are separate")
    lines={};e.secret=true;e.SlashCmdList.FLUXBARS("audit")
    check(lines[19]:find("action=spell/<private>",1,true),family..": inaccessible IDs stay private")
    lines={};e.locked=true;reads=0;e.SlashCmdList.FLUXBARS("audit")
    check(#lines==1 and reads==0,family..": combat guard avoids querying the bar")
    lines={};e.locked=false;e.shift=true;e.SlashCmdList.FLUXBARS("audit")
    check(#lines==1 and reads==0,family..": held modifier requires neutral audit")
    lines={};e.shift=false;e.page=private;e.SlashCmdList.FLUXBARS("audit")
    check(#lines==1 and reads==0,family..": private page is not used in slot arithmetic")
end
print(("Main-row audit: %d checks PASS across five client models; read-only; native results pending"):format(checks))
