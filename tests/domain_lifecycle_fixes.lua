-- Complete production proxy creation/rebuild functions, with native frames and
-- third-party handlers mocked. No addon, global-client or input writes occur.
local f=assert(io.open("MicroMenu/FluxMinimapToMicro.lua","rb"));local source=f:read("*a"):gsub("\r\n","\n");f:close()
local begin=source:find("local proxyButtons = {}",1,true) or assert(source:find("function M:RebuildMicroButtons()",1,true))
local finish=assert(source:find("-- Integration with FluxAddonMicroButton",begin,true))
local body=source:sub(begin,finish-1)
local factoryFile=assert(io.open("MicroMenu/FluxMicroMenu.lua","rb"));local factorySource=factoryFile:read("*a"):gsub("\r\n","\n");factoryFile:close()
local factoryBegin=assert(factorySource:find("function FluxMicroMenu:CreateMicroButton(",1,true))
local factoryEnd=assert(factorySource:find("--- Config preview: draw one static frame",factoryBegin,true))
local checks=0;local function check(v,why)checks=checks+1;assert(v,why)end
local function boot(client)
    local s={objects={},proxyCreates=0,hooks=0,iconUpdates=0,rebuilds=0,shown=0,positioned=true,enabled=true}
    local e=setmetatable({},{__index=_G});e._G=e;e.BUTTON_PRIORITIES={}
    local methods={}
    local function object(name,parent)
        local o=setmetatable({name=name,parent=parent,shown=true,scripts={},hooks={},secureHooks={}},{__index=methods})
        s.objects[#s.objects+1]=o;return o
    end
    function methods:Show()self.shown=true end;function methods:Hide()local was=self.shown;self.shown=false;if was then for _,fn in ipairs(self.hooks.OnHide or{})do fn(self)end end end
    function methods:IsShown()return self.shown end;function methods:SetParent(p)self.parent=p end
    function methods:GetParent()return self.parent end;function methods:GetName()return self.name end
    function methods:SetScript(k,v)self.scripts[k]=v end;function methods:GetScript(k)return self.scripts[k]end
    function methods:HookScript(k,v)self.hooks[k]=self.hooks[k]or{};self.hooks[k][#self.hooks[k]+1]=v end
    function methods:GetLeft()return s.positioned and 100 or nil end;function methods:GetRight()return s.positioned and 132 or nil end
    function methods:RegisterForClicks()end;function methods:SetTexture()for _,cb in ipairs(self.secureHooks.SetTexture or{})do cb()end end
    function methods:SetAtlas()for _,cb in ipairs(self.secureHooks.SetAtlas or{})do cb()end end
    function methods:CreateTexture()return object(nil,self)end
    function methods:SetNormalTexture()self.normal=object(nil,self)end;function methods:GetNormalTexture()return self.normal end
    function methods:SetPushedTexture()self.pushed=object(nil,self)end;function methods:GetPushedTexture()return self.pushed end
    function methods:SetSize()end;function methods:SetPoint()end;function methods:SetTexCoord()end;function methods:SetVertexColor()end
    e.CreateFrame=function(_,name,parent)
        if name and name:find("^FluxMinimap2Micro_")then s.proxyCreates=s.proxyCreates+1 end
        local obj=object(name,parent);if name then e[name]=obj end;return obj
    end;e.UIParent=object("UIParent");e.unpack=table.unpack
    e.wipe=function(t)for k in pairs(t)do t[k]=nil end end
    e.hooksecurefunc=function(o,k,cb)o.secureHooks[k]=o.secureHooks[k]or{};o.secureHooks[k][#o.secureHooks[k]+1]=cb;s.hooks=s.hooks+1 end
    local tooltip={shown=false}
    function tooltip:Show()self.shown=true;s.shown=s.shown+1 end;function tooltip:Hide()self.shown=false end
    function tooltip:SetOwner(o)self.owner=o end;function tooltip:IsOwned(o)return self.owner==o end
    function tooltip:SetText(t)self.text=t end;function tooltip:ClearLines()end;function tooltip:ClearAllPoints()end
    function tooltip:SetPoint(...)self.anchor={...}end;function tooltip:GetOwner()return self.owner end;function tooltip:SetAnchorType(v)self.anchorType=v end;function tooltip:AddLine()end;function tooltip:AddDoubleLine()end
    e.GameTooltip=tooltip;s.tooltip=tooltip;s.originalShow=tooltip.Show
    e.FluxMicroMenu={Rebuild=function()s.rebuilds=s.rebuilds+1 end};e.fixtureHud=client=="live"or client=="forever"
    assert(load("local UseDfHudMicroButtonShell=function()return fixtureHud end;local ApplyClassicCustomMicroMouseover=function()end;local ApplyDfCustomMicroMouseover=function()end\n"
        ..factorySource:sub(factoryBegin,factoryEnd-1),"@actual-micro-button-factory","t",e))()
    local original=object("AddonMapIcon",e.UIParent);original.icon=object(nil,original)
    local M={createdMicroButtons={},scannedButtons={original},buttonNameMap={Addon=original}}
    function M:GetEnabledButtonsOrdered()return s.enabled and{"Addon"}or{}end
    function M:GetButtonIcon()return 123 end;function M:GetFriendlyMinimapButtonName()return"Addon"end
    function M:GetButtonIconTexture(btn)return btn.icon end
    function M:UpdateMicroButtonIconFromMinimap()s.iconUpdates=s.iconUpdates+1 end
    assert(load("local M=...\n"..body,"@actual-minimap-proxy","t",e))(M)
    function s.tick()
        local active={};for _,o in ipairs(s.objects)do if o.shown and o.scripts.OnUpdate then active[#active+1]=o end end
        for _,o in ipairs(active)do o.scripts.OnUpdate(o,.016)end
    end
    function s.enter(btn)if btn.scripts.OnEnter then btn.scripts.OnEnter(btn)end;for _,cb in ipairs(btn.hooks.OnEnter or{})do cb(btn)end end
    function s.leave(btn)if btn.scripts.OnLeave then btn.scripts.OnLeave(btn)end;for _,cb in ipairs(btn.hooks.OnLeave or{})do cb(btn)end end
    s.M,s.e,s.original=M,e,original;return s
end

for _,client in ipairs({"era","anniversary","live","forever"})do
    local s=boot(client);s.original.dataObject={OnTooltipShow=function(tt)tt:SetText("Broker")end}
    s.positioned=false;s.M:RebuildMicroButtons();local button=s.M.createdMicroButtons[1]
    s.enter(button);s.leave(button);s.positioned=true;s.tick()
    check(not s.tooltip.shown,"departed broker tooltip cannot reappear")
    s.enter(button);check(s.tooltip.shown and s.tooltip.text=="Broker"and s.tooltip.owner==button,"positive broker tooltip remains direct/native")
    s.leave(button)
    s.original.dataObject=nil
    s.original.scripts.OnEnter=function(original)
        check(s.tooltip.Show==s.originalShow,"standard handler sees unchanged shared Show method")
        s.tooltip:SetOwner(original);s.tooltip:SetText("Native lines/widgets");s.tooltip:Show()
    end
    s.enter(button);check(s.tooltip.owner==s.original and s.tooltip.anchor[2]==button,"standard tooltip retains native owner and proxy anchor")
    s.tooltip:SetText("Async native update");s.tick()
    check(s.tooltip.text=="Async native update"and s.tooltip.Show==s.originalShow,"late data retained without copying/replacing native tooltip methods")
    s.leave(button);s.tick();check(not s.tooltip.shown,"standard leave cancels deferred reanchor")
    -- Enable cycles must reuse frames and the two original-icon hooks.
    local created=#s.objects
    for i=1,500 do s.enabled=false;s.M:RebuildMicroButtons();s.tick();s.enabled=true;s.M:RebuildMicroButtons();s.tick()end
    check(s.proxyCreates==1 and s.hooks==2 and #s.objects==created,"500 enable cycles retain one proxy and bounded drivers/hooks")
    s.iconUpdates=0;s.original.icon:SetTexture(77);check(s.iconUpdates==1,"one original icon change updates its one current proxy")
    local rebuilds=s.rebuilds
    for i=1,1000 do s.M:RebuildMicroButtons()end
    s.tick();check(s.rebuilds==rebuilds+1 and #s.objects==created,"same-frame rebuild storm coalesces on the existing driver")
    -- Replacing the original keeps the proxy and current click/tooltip identity.
    local replacement=setmetatable({name="NewMapIcon",parent=s.e.UIParent,shown=true,scripts={},hooks={},secureHooks={}},getmetatable(s.original))
    replacement.icon=setmetatable({parent=replacement,secureHooks={}},getmetatable(s.original.icon))
    local clicks=0;replacement.scripts.OnClick=function(self,mouse,down)check(self==replacement and mouse=="RightButton"and down==true,"click forwards current original and edge");clicks=clicks+1 end
    s.M.buttonNameMap.Addon=replacement;s.M:RebuildMicroButtons();s.tick()
    check(s.M.createdMicroButtons[1]==button and s.original._fluxMicroBtn==nil,"replacement rebinds same proxy and removes old icon dispatch")
    for _,callback in ipairs(button.hooks.OnClick or{})do callback(button,"RightButton",true)end
    check(clicks==1,"proxy click handler no longer captures the retired original")
    s.iconUpdates=0;s.original.icon:SetTexture(1);check(s.iconUpdates==0,"retired icon hook cannot repaint a replacement")
    replacement.icon:SetTexture(2);check(s.iconUpdates==1,"replacement owns one icon update")
    local other=s.M:CreateMicroButtonForMinimap("Other",s.original,2)
    s.original.dataObject={OnTooltipShow=function(tt)tt:SetText("Other")end}
    s.enter(button);s.enter(other);s.leave(button)
    check(s.tooltip.shown and s.tooltip.owner==other,"stale leave does not hide a newer proxy tooltip")
    other:Hide();s.tick();check(not s.tooltip.shown,"hide cancels the owned tooltip")
end
print("Domain proxy lifecycle: "..checks.." checks; actual micro factory/rebuild/hover/click, four policies; native taint/pixels pending")

-- Reuse the permanent strict full-module fixture, extending its hidden-only
-- combat case to a visible overlay and a native secure-show callback.
do
    local f=assert(io.open("tests/salvage_overlay.lua","rb"));local script=f:read("*a"):gsub("\r\n","\n");f:close()
    local cut=assert(script:find("local function exercise(branch, options, code)",1,true))
    local fixture=assert(load(script:sub(1,cut-1).."\nreturn fixture","@strict-salvage-fixture","t",_G))()
    for _,client in ipairs({"classic_era","classic_anniversary","classic","live","forever"})do
        local e,S,o=fixture(client,{atlas=false})
        S.ApplySpellToBagSlot(0,2,1804,e.CreateColor(1,0,0),e.owner)
        check(o:IsShown()and o.scripts.OnUpdate,"out-of-combat action/driver retained")
        e.combat=true
        check(pcall(o.RunScript,o,"OnUpdate",.04),"visible combat tick issues no protected mutation")
        check(o.scripts.OnUpdate==nil,"combat parks the anchor driver")
        for i=1,1000 do check(pcall(e.fire,"MODIFIER_STATE_CHANGED"),"combat modifier event avoids protected anchor")end
        e.combat=false;e.fire("PLAYER_REGEN_ENABLED")
        check(o.scripts.OnUpdate~=nil and o:IsShown(),"one regen reconciliation retains the visible action and cadence")
        S.HideOverlay();check(o.scripts.OnUpdate==nil and not o:IsShown(),"ordinary hide retains cleanup")
        -- Model a secure driver show without calling insecure Show.
        e.combat=true;o.shown=true
        check(pcall(o.RunScript,o,"OnShow"),"secure combat show performs no protected geometry/attribute writes")
        check(o.scripts.OnUpdate==nil,"secure combat show waits for safe anchor reconciliation")
        S.HideOverlay();e.combat=false;e.fire("PLAYER_REGEN_ENABLED")
        check(not o:IsShown()and o.scripts.OnUpdate==nil,"coalesced deferred hide beats a stale pending anchor")
    end
end
print("Domain lifecycle total: "..checks.." checks; visible salvage combat transition/secure-show cleanup covered")

