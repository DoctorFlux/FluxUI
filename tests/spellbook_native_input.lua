-- Exercise addon spellbook input with native callbacks that reject manual
-- execution. WoW's full taint propagation still requires in-game verification.
local checks=0
local function check(ok,message)assert(ok,message);checks=checks+1 end
local function read(path)local f=assert(io.open(path,"rb"));local text=f:read("*a"):gsub("\r\n","\n");f:close();return text end
local function fixture(branch,source)
    local s={frames={},queue={},callbacks={},nativeEnter=0,nativeLeave=0,nativeClicks=0,bindings=0,inBlizzardEvent=false}
    local env=setmetatable({},{__index=_G});env._G=env
    local methods={}
    local function object(owned,parent)
        return setmetatable({owned=owned,parent=parent,shown=true,scripts={},hooks={},events={},level=10,mouse=false},{__index=methods})
    end
    function methods:RegisterEvent(event)self.events[event]=true end
    function methods:UnregisterAllEvents()self.events={}end
    function methods:SetScript(key,fn)assert(self.owned,"native SetScript");self.scripts[key]=fn end
    function methods:HookScript(key,fn)
        assert(key~="OnClick" and key~="OnMouseDown" and key~="OnMouseUp","native click script hook")
        self.hooks[key]=self.hooks[key] or {};table.insert(self.hooks[key],fn)
    end
    function methods:GetScript(key)return self.scripts[key]end
    function methods:RegisterForClicks(...)assert(self.owned,"native click registration");self.clicks={...}end
    function methods:SetPassThroughButtons(...)assert(self.owned,"native passthrough write");self.pass={...}end
    function methods:SetPropagateMouseMotion(value)assert(self.owned,"native motion write");self.propagateMotion=value end
    function methods:SetPropagateMouseClicks(value)assert(self.owned,"native click propagation write");self.propagateClicks=value end
    function methods:EnableMouse(value)assert(self.owned,"native input write");self.mouse=value end
    function methods:GetParent()return self.parent end
    function methods:SetParent(value)assert(self.owned,"native reparent");self.parent=value end
    function methods:SetAllPoints(value)assert(not s.inBlizzardEvent,"decoration inside native spellbook handler");self.anchor=value end
    function methods:SetPoint()assert(not s.inBlizzardEvent,"decoration inside native spellbook handler")end
    function methods:ClearAllPoints()end
    function methods:GetFrameLevel()return self.level end
    function methods:SetFrameLevel(value)self.level=value end
    function methods:SetFrameStrata()end
    function methods:SetSize()end
    function methods:SetText()end
    function methods:GetName()return self.name end
    function methods:IsShown()return self.shown end
    function methods:Hide()self.shown=false end
    function methods:Show()self.shown=true end
    env.UIParent=object(false)
    env.CreateFrame=function(_,_,parent)local f=object(true,parent);s.frames[#s.frames+1]=f;return f end
    env.InCombatLockdown=function()return false end
    env.C_Timer={After=function(_,fn)s.queue[#s.queue+1]=fn end}
    env.Enum={SpellBookItemType={Spell=1,PetAction=2},SpellBookSpellBank={Player=0,Pet=1}}
    env.C_Spell={IsSpellPassive=function()return false end}
    local client={isRetail=branch=="live" or branch=="forever",isForever=branch=="forever",isCamelot=branch=="forever"}
    env.Flux={Client=client};env.FLUX_API=client
    env.FluxSpellBindingEditor_Open=function(info)s.bindings=s.bindings+1;s.selected=info end
    env.EventRegistry={RegisterCallback=function(_,key,fn)s.callbacks[key]=fn end}
    local book=object(false)
    local modern=client.isRetail
    if modern then
        env.PlayerSpellsFrame=object(false);env.PlayerSpellsFrame.SpellBookFrame=book
        s.row=object(false,book);s.row.spellBank=0
        s.row.spellBookItemInfo={itemType=1,spellID=133,actionID=133}
        s.button=object(false,s.row);s.row.Button=s.button
        book.ForEachDisplayedSpell=function(_,fn)fn(s.row)end
    else
        env.SpellBookFrame=book;book.bookType="spell"
        env.SpellBook_GetSpellBookSlot=function()return 1,"SPELL",133 end
        env.GetSpellBookItemName=function()return "Fireball",nil,133 end
        s.button=object(false,book);s.button.name="SpellButton1";env.SpellButton1=s.button
    end
    env.GameTooltip={IsShown=function()return true end,GetOwner=function()return s.button end,AddLine=function()s.tipLines=(s.tipLines or 0)+1 end,
        Show=function()end,Hide=function()end}
    s.button.scripts.OnEnter=function()
        assert(s.nativeContext,"native hover forwarded from addon")
        s.nativeEnter=s.nativeEnter+1
    end
    s.button.scripts.OnLeave=function()
        assert(s.nativeContext,"PetActionBar/ EditMode reached from addon hover")
        s.nativeLeave=s.nativeLeave+1
    end
    s.button.scripts.OnClick=function()
        assert(s.nativeContext,"CastSpellBookItem reached from addon click")
        s.nativeClicks=s.nativeClicks+1
    end
    s.originalClick=s.button.scripts.OnClick
    assert(load(source or read("Binding/UI/SpellbookBindingHooks.lua"),"@SpellbookBindingHooks.lua","t",env))("_FluxUI")
    function s.Login()
        for _,f in ipairs(s.frames)do if f.events.PLAYER_LOGIN then f.scripts.OnEvent(f,"PLAYER_LOGIN") end end
    end
    function s.Flush()while #s.queue>0 do local queue=s.queue;s.queue={};for _,fn in ipairs(queue)do fn()end end end
    function s.NativeHover(key)
        s.nativeContext=true;s.button.scripts[key](s.button);s.nativeContext=false
        for _,fn in ipairs(s.button.hooks[key] or {})do fn(s.button)end
    end
    return s,env,book
end

local function exercise(branch,source)
    local s,e,book=fixture(branch,source)
    s.inBlizzardEvent=true;s.Login();s.inBlizzardEvent=false;s.Flush()
    local catcher=s.button.__FluxBindingCatcher
    check(catcher and catcher.owned and catcher.mouse,branch.." addon right-click catcher active")
    check(catcher.clicks[1]=="RightButtonUp" and catcher.pass[1]=="LeftButton",branch.." native left clicks pass through")
    check(catcher.propagateMotion and not catcher.propagateClicks,branch.." engine owns native hover delivery")
    -- Old code manually called native handlers from these addon callbacks.
    for _,key in ipairs({"OnEnter","OnLeave"})do if catcher.scripts[key]then catcher.scripts[key](catcher)end end
    check(s.nativeEnter==0 and s.nativeLeave==0,branch.." catcher never calls native hover handlers")
    s.NativeHover("OnEnter");s.Flush();s.NativeHover("OnLeave")
    check(s.nativeEnter==1 and s.nativeLeave==1 and s.tipLines==1,branch.." native hover and binding hint preserved")
    catcher.scripts.OnClick(catcher,"LeftButton")
    check(s.bindings==0 and s.nativeClicks==0,branch.." addon does not cast or bind on left click")
    s.nativeContext=true;s.button.scripts.OnClick(s.button,"LeftButton");s.nativeContext=false
    check(s.nativeClicks==1 and s.button.scripts.OnClick==s.originalClick,branch.." native cast handler keeps ownership")
    catcher.scripts.OnClick(catcher,"RightButton")
    check(s.bindings==1 and s.selected.spellID==133,branch.." right click still selects spell for binding")
    if s.callbacks["PlayerSpellsFrame.SpellBookFrame.Show"]then
        s.inBlizzardEvent=true
        s.callbacks["PlayerSpellsFrame.SpellBookFrame.Show"]()
        s.callbacks["PlayerSpellsFrame.SpellBookFrame.DisplayedSpellsChanged"]()
        s.inBlizzardEvent=false
        check(#s.queue==1,branch.." book/page refresh coalesces outside native grid stack")
        s.Flush()
        book.shown=false;s.callbacks["PlayerSpellsFrame.SpellBookFrame.Show"]();s.Flush()
        check(s.bindings==1,branch.." queued refresh tolerates closed book")
    end
end
for _,branch in ipairs({"live","forever","classic_era","classic_anniversary","classic"})do exercise(branch)end
local source=read("Binding/UI/SpellbookBindingHooks.lua")
local insertion='        catcher:SetScript("OnClick", function(self, mouseButton)'
local first=assert(source:find(insertion,1,true))
local mutant=source:sub(1,first-1)..[[        catcher:SetScript("OnLeave", function(self)
            local button = self:GetParent()
            button:GetScript("OnLeave")(button)
        end)
]]..source:sub(first)
local ok,err=pcall(exercise,"live",mutant)
check(not ok and tostring(err):find("reached from addon hover",1,true),"negative control rejects native OnLeave forwarding")

-- Execute the real CLEU capability block without unrelated startup dependencies.
local capSource=read("Core/Capabilities.lua")
local a=assert(capSource:find("do\n\t-- Live Midnight forbids",1,true))
local b=assert(capSource:find("-- Post-DF live and Forever",a,true))
for _,mode in ipairs({"absent","false","true","error"})do
    local calls=0
    local cap={}
    local e={Client={isLiveMidnight=true},Cap=cap,pcall=pcall,
        CreateFrame=function()calls=calls+1;error("Live combat-log probe")end}
    if mode~="absent"then e.C_CombatLog={IsCombatLogRestricted=function()
        if mode=="error"then error("query unavailable")end
        return mode=="true"
    end}end
    assert(load(capSource:sub(a,b-1),"@Core/Capabilities.lua:CLEU","t",e))()
    check(calls==0 and cap.hasCombatLogUnfiltered==false,"Live capability skips forbidden probe with "..mode.." query")
end
print("PASS spellbook native input: "..checks.." checks across five client models; native taint unverified")
