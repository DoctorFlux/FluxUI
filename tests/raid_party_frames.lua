-- Actual party controller and five pinned secure state handlers. Visual helpers
-- are modeled; this does not establish native pixels, hardware input or taint.
local function read(path)
    local f=assert(io.open(path,"rb"));local s=f:read("*a"):gsub("\r\n","\n");f:close();return s
end
local shared=read("tests/raid_healer_secure.lua")
local prefix=shared:sub(1,assert(shared:find("local function exercise(client)",1,true))-1)
prefix=prefix:gsub('local ns = { Flux = {} }','local ns = { Flux = {} }; e.ns=ns')
if os.getenv("FLUX_PARTY_SECURE_SOURCE")then
    prefix=prefix:gsub('root %.%. "RaidFrame/FluxRaidSecure.lua"',string.format("%q",os.getenv("FLUX_PARTY_SECURE_SOURCE")))
end
prefix=prefix:gsub("return e, secure, execute", "e.resolveDriver=resolveDriver; return e, secure, execute")
local fixture=assert(load(prefix.."\nreturn fixture","@native-secure-fixture","t",_G))()
local checks=0
local function check(value,label)checks=checks+1;assert(value,label)end
local function near(a,b)return math.abs(a-b)<1e-7 end

for _,client in ipairs({"live","forever","classic","classic_era","classic_anniversary"})do
    local e,secure=fixture(client)
    local ns,db=e.ns,{partyAsRaid=true,partyFrameScale=.55,partyPetScale=1}
    local S=e.FluxRaidSecure
    local calls,timers,deferred={}, {}, {}
    ns.Flux.securePhaseReady=true
    ns.Flux.Combat={Defer=function(key,fn)deferred[key]=fn end}
    ns.Flux.Module={Register=function(_,entry)e.module=entry end}
    e.UIParent=e.CreateFrame("Frame","UIParent")
    e.FluxRaidState={containerFrame=e.CreateFrame("Frame","RaidDock")}
    e.FluxOptions={GetRaidFrameDB=function()return db end}
    e.FluxRaidVisuals={FRAME_HEIGHT=42,CELL_JOIN_OVERLAP=4,GetFluxRaidOptionTable=function()return {displayOnlyDispellableDebuffs=db.strict}end}
    e.C_Timer={After=function(_,fn)timers[#timers+1]=fn end}
    e.ClickCastFrames={}
    ns.FluxMouseoverKeybind={RegisterFrame=function(_,button)calls[#calls+1]={"binding",button}end}
    local methods=getmetatable(e.UIParent).__index
    -- The client exposes GetFrameRef only inside restricted code. Catch the
    -- reported ordinary-Lua cleanup regression instead of masking it in mocks.
    function methods:GetFrameRef(key)assert(e.depth>0,"ordinary GetFrameRef is unavailable");return self.refs[key]end
    function methods:SetScale(value)assert(not e.combat);self.scale=value end
    function methods:GetScale()return self.scale or 1 end
    function methods:GetEffectiveScale()return self:GetScale()*(self.parent and self.parent:GetEffectiveScale()or 1)end
    function methods:GetFrameLevel()return 40 end
    function methods:GetFrameStrata()return "MEDIUM"end
    function methods:SetFrameLevel(value)self.level=value end
    function methods:SetAllPoints(frame)self.allpoints=frame end
    function methods:SetSize(w,h)assert(not e.combat);self.width,self.height=w,h end
    function methods:SetScript(key,fn)self.scripts[key]=fn end
    function methods:GetScript(key)return self.scripts[key]end
    function methods:GetParent()return self.parent end
    local nativePoint=methods.SetPoint
    function methods:SetPoint(...)
        nativePoint(self,...);self.points=self.points or{};self.points[#self.points+1]=self.point
    end
    local nativeClear=methods.ClearAllPoints
    function methods:ClearAllPoints()nativeClear(self);self.points={}end
    function methods:SetFrameStrata(v)self.strata=v end
    function methods:RegisterForClicks()end
    function methods:SetStatusBarTexture()end
    function methods:GetStatusBarTexture()return {SetHorizTile=function()end,SetVertTile=function()end,SetTexCoord=function()end}end
    function methods:SetOrientation(v)self.orientation=v end
    function methods:SetMinMaxValues(a,b)self.minimum,self.maximum=a,b end
    function methods:SetValue(v)self.value=v end
    function methods:SetStatusBarColor(...)self.color={...}end
    function methods:CreateTexture()
        return {SetAllPoints=function()end,SetTexture=function(s,v)s.texture=v end,SetVertexColor=function(s,...)s.color={...}end,
            SetTexCoord=function(s,...)s.uv={...}end,
            SetSize=function(s,w,h)s.width,s.height=w,h end,SetHeight=function(s,h)s.height=h end,
            SetColorTexture=function(s,...)s.color={...}end,SetPoint=function(s,...)s.point={...}end,
            ClearAllPoints=function(s)s.point=nil end,SetDrawLayer=function()end,SetAtlas=function(s,a)s.atlas=a end,
            Show=function(s)s.shown=true end,Hide=function(s)s.shown=false end,IsShown=function(s)return s.shown end}
    end
    function methods:HookScript(key,fn)
        local old=self.scripts[key];self.scripts[key]=function(...)if old then old(...)end;fn(...)end
    end
    function methods:RegisterUnitEvent()end
    e.SecureUnitButton_OnLoad=function()end
    function methods:RegisterEvent()end
    function methods:UnregisterEvent()end
    function methods:UnregisterAllEvents()self.noEvents=true end
    function methods:SetMouseClickEnabled(value)self.mouseClick=value end
    function methods:SetShown(value)if value then self:Show()else self:Hide()end end
    local function text()return {SetText=function(s,v)s.text=v end,SetAlpha=function(s,a)s.alpha=a end,
        SetTextScale=function(s,v)s.textScale=v end,SetWidth=function(s,v)s.width=v end,SetShown=function(s,v)s.shown=v end,Show=function(s)s.shown=true end,Hide=function(s)s.shown=false end,
        ClearAllPoints=function(s)s.points={}end,SetPoint=function(s,...)s.points=s.points or{};s.points[#s.points+1]={...}end}end
    local function bar()
        local f=e.CreateFrame("StatusBar");f.Percent=text();f.Value=text();return f
    end
    local UF={}
    ns.UnitFrames=UF
    UF.CreateBaseFrame=function(unit,parent,w,h,_,options)
        calls[#calls+1]={"base",unit,w,h,options}
        local frame=e.CreateFrame("Button",options and options.name or "FluxUnitFrame_"..unit,parent)
        frame.unit=unit;frame.width,frame.height=w,h;frame._fluxPartyPreview=options and options.preview
        frame:SetAttribute("unit",unit)
        frame.UpdatePartition=function(s)calls[#calls+1]={"partition",s};s:UpdateOuterBorder()end
        frame.UpdateOuterBorder=function(s)
            calls[#calls+1]={"chrome",s}
            if s.classIcon then
                s.classIcon:SetSize(36,36);s.classIcon:SetPoint("TOPLEFT",s.outerBorderFrame,"TOPLEFT",0,-4);s.classIcon:Show()
                s.specIcon:SetPoint("TOPLEFT",s.classIcon,"TOPRIGHT",0,0)
            end
        end
        return frame
    end
    UF.CreateHealthBar=function(f)f.Health=bar()end
    UF.CreatePowerBar=function(f)f.Power=bar()end
    UF.CreatePortrait=function(f)f.PortraitFrame=e.CreateFrame("Frame",nil,f);f.Portrait={}end
    UF.CreateAtlasBorder=function(f)f.atlasBorderFrame=e.CreateFrame("Frame",nil,f)end
    UF.CreateOuterBorder=function(f)
        f.outerBorderFrame=e.CreateFrame("Button",nil,f);f.nameText=text();f.levelText=text()
        for _,key in ipairs({"classIcon","specIcon","pvpIcon","raidIcon","leaderIcon","assistantIcon","mainTankIcon","mainAssistIcon","masterLooterIcon"})do
            f[key]=f.outerBorderFrame:CreateTexture();f[key]:Hide()
        end
    end
    UF.UpdateHealth=function(f)calls[#calls+1]={"health",f.unit}end
    UF.UpdatePower=function(f)calls[#calls+1]={"power",f.unit}end
    UF.UpdatePortrait=function(f,unit)calls[#calls+1]={"portrait",unit}end
    ns.CastBar={CreateCastBar=function(f,unit)
        f.CastBar=e.CreateFrame("Frame",nil,f);calls[#calls+1]={"cast",unit}
        f.CastBar.IconFrame=e.CreateFrame("Frame",nil,f.CastBar)
        local native=function()
            f.CastBar:SetPoint("LEFT",f.atlasBorderFrame,"RIGHT",0,0);f.CastBar:SetHeight(40)
            f.CastBar.IconFrame:SetSize(40,40)
        end
        f.CastBar.UpdateLayout=native;f.CastBar._nativeLayout=native
    end,RefreshCastForUnit=function(bar,unit)
        calls[#calls+1]={"castRefresh",unit}
        if e.activePartyCast then bar:Show();bar.IconFrame:Show()else bar:Hide()end
    end}
    local ufSource=read("UnitFrames/FluxUnitFrames_Shared.lua")
    local a=assert(ufSource:find("function UF.LayoutRaidMarker",1,true));local b=assert(ufSource:find("function UF.UpdateOuterBorder",a,true))
    e.UF=UF;e.ValueIsSecret=function(v)return e.issecretvalue and e.issecretvalue(v)end
    assert(load(ufSource:sub(a,b-1),"@shared-player-raid-marker","t",e))()
    local sepFirst=assert(ufSource:find("local function CreateSeparator(parent)",1,true))
    local sepLast=assert(ufSource:find("local AnimatedHealthLossMixin",sepFirst,true))
    assert(load(ufSource:sub(sepFirst,sepLast-1),"@shared-target-divider","t",e))()
    e.FluxRaidAuras={Setup=function(f)calls[#calls+1]={"auras",f.unit}end,Refresh=function()end,
        Update=function(f)f.lastStrict=f.optionTable.displayOnlyDispellableDebuffs end,Clear=function()end}
    local states={}
    local originalRegister=ns.Flux.Restricted.RegisterPagingDriver
    local originalUnregister=ns.Flux.Restricted.UnregisterPagingDriver
    e.SecureCmdOptionParse=function(condition)
        if condition=="hide"then return "hide"end
        local token=condition:match("@(party%dtarget)")or condition:match("@(partypet%d)")or condition:match("@(party%d)")
        if not token then return "hide"end
        local index=tonumber(token:match("(%d)"))
        local grouped=not condition:find("group:party",1,true)or e.mode=="party"
        local show=grouped and index<=e.partyCount and(not token:match("^partypet")or e.pets[index])and(not token:match("target$")or e.targets[index])
        return show and"show"or"hide"
    end
    local function refresh()
        secure(function()for owner,list in pairs(states)do for state,condition in pairs(list)do e.resolveDriver(owner,"state-"..state,condition)end end end)
    end
    ns.Flux.Restricted.RegisterPagingDriver=function(owner,state,condition)
        if state=="visibility"or state=="petlayout"then
            assert(not e.combat);states[owner]=states[owner]or{};states[owner][state]=condition;refresh();return true
        end
        return originalRegister(owner,state,condition)
    end
    ns.Flux.Restricted.UnregisterPagingDriver=function(owner,state)
        if state=="visibility"or state=="petlayout"then assert(not e.combat);if states[owner]then states[owner][state]=nil end;return true end
        return originalUnregister(owner,state)
    end
    e.pets={};e.targets={}
    e.UnitHealth=function()return 80 end;e.UnitHealthMax=function()return 100 end;e.UnitIsConnected=function()return true end
    assert(loadfile("UnitFrames/FluxUnitFrames_Party.lua","t",e))("_FluxUI",ns)
    local P=ns.PartyFrames
    local opaque=setmetatable({},{__eq=function()error("opaque comparison")end})
    e.issecretvalue=function(v)return rawequal(v,opaque)end
    for _,state in ipairs({"offline","dead","ghost","afk","normal","opaque"})do
        e.UnitIsConnected=function()if state=="opaque"then return opaque end;return state~="offline"end
        e.UnitIsDead=function()return state=="dead"end;e.UnitIsGhost=function()return state=="ghost"end
        e.UnitIsAFK=function()return state=="afk"end
        local expected=({offline="Offline",dead="Dead",ghost="Ghost",afk="AFK"})[state]
        check(P.GetStatusText("party1")==expected,"status precedence handles offline/dead/ghost/AFK and opaque connection")
    end
    e.UnitIsConnected=function()return true end;e.UnitIsDead=function()return false end
    e.UnitIsGhost=function()return false end;e.UnitIsAFK=function()return false end
    check(P.ApplyOptions()and #P.members==0,"default raid-party mode creates no alternate cells and cleanup needs no ordinary GetFrameRef")
    db.partyAsRaid=false
    check(P.ApplyOptions()and P.ready and #P.members==4 and #P.pets==4,"all four owners and pets prepared before exposure")
    local member=P.members[1]
    check(member._fluxAuraLayer.level>member._fluxPartyIndicatorLayer.level and member._fluxAuraLayer.level<member.CastBar.level,
        "party aura host is above portrait indicators and below cast header")
    check(member.classIcon.shown and member.classIcon.width==36 and member.classIcon.point[2]==member.outerBorderFrame,
        "party preserves the shared player class icon slot and size")
    check(member.specIcon.point[2]==member.classIcon and member.specIcon.point[3]=="TOPRIGHT","spec stays adjacent to class using player factory anchor")
    check(member.raidIcon.point[1]=="CENTER"and member.raidIcon.point[2]==member.Health,"party and player execute the same HP-centered raid-marker layout")
    member.leaderIcon:Show();member.masterLooterIcon:Show();member.mainTankIcon:Show();P.LayoutIndicators(member)
    check(member.leaderIcon.point[5]~=member.masterLooterIcon.point[5] and member.masterLooterIcon.point[4]~=member.mainTankIcon.point[4],"leader/loot/tank have separate compact slots")
    check(member._fluxPartyDivider.height==17 and member._fluxPartyDivider.texture=="Interface\\AddOns\\_FluxUI\\Texture\\BattlefieldMinimap.tga"
        and member._fluxPartyDivider.point[2]==member.Power
        and member._fluxPartyDivider.point[3]=="TOPRIGHT"and member._fluxPartyDivider.point[5]==1,
        "divider follows resource top, not the extended HUD health fill bottom")
    check(member.CastBar.UpdateLayout~=member.CastBar._nativeLayout and member.CastBar.level==150,
        "party raises shared cast art over name70/metadata80 layers")
    check(member.CastBar.height==40 and member.CastBar.IconFrame.width==40 and member.CastBar.IconFrame.point[2]==member.outerBorderFrame,
        "player cast shape and spell icon are retained in the header")
    check(member.Health.Value.textScale>member.nameText.textScale,"values and percentages are larger than the fitted name")
    check(near(member.Health.Value.textScale,member.Health.Percent.textScale)and near(member.Power.Percent.textScale,member.Health.Value.textScale),"HP and resource values/percentages share enlarged scale")
    check(member.Power.Percent.shown and not member.Power.Value.shown and member.Health.Value.shown and not member.Health.Percent.shown,"default is HP values and resource percent only")
    check(P.targets[1].width==30 and P.targets[1].orientation==nil and P.targets[1].HealthBar.orientation=="VERTICAL","target uses wider HP-only vertical bar")
    check(not P.pets[1].PortraitFrame and P.pets[1]._fluxHealthBarOnly,"small pet has no portrait and is HP-only")
    local header=e.CreateFrame("Frame","Group1")
    check(S.ConfigureHeader(header,1,false)and header.attrs.showParty==false,"normal mode disables only the raid header's party capability")
    S.RefreshRosterLayout(e.FluxRaidState.containerFrame,{},nil,{colStep=69,columnHeight=194})
    local created=e.created
    e.combat=true
    for count=1,4 do
        e.mode,e.partyCount="party",count;e.pets[count]=true;refresh()
        for i=1,4 do
            local frame,pet=P.members[i],P.pets[i]
            check(frame.shown==(i<=count)and pet.shown==(i<=count and e.pets[i]==true),"native party/pet existence owns actual combat visibility")
            check(frame.attrs.unit=="party"..i and pet.attrs.unit=="partypet"..i,"prepared buttons retain real unit tokens")
        end
        local last=P.members[count]
        local compactBottom=-194+(4-count)*(121*last.scale)
        check(last.point[1]=="BOTTOMRIGHT"and last.point[3]=="TOPRIGHT"and near(last.point[5]*last.scale,compactBottom),
            "new final member matches the unchanged compact party bottom at every roster count")
        check(last.point[4]==-2,"portrait overlap is compensated at the shared right edge")
        for i=2,count do
            check(near((P.members[i-1].point[5]-P.members[i].point[5])*last.scale,121*last.scale),
                "adjacent member outer frames touch with exactly zero layout spacing")
        end
    end
    for count=3,1,-1 do e.partyCount=count;refresh();check(not P.members[count+1].shown,"combat leave retires previous final member")end
    e.pets[1]=false;refresh();check(P.members[1].shown and not P.pets[1].shown,"combat pet dismissal leaves its owner visible")
    e.pets[1]=true;refresh();check(P.pets[1].shown,"combat summon reuses the prepared pet")
    check(member._fluxPartyHealthTextAnchor.point[1]=="TOPRIGHT" and member._fluxPartyHealthTextAnchor.height==member._fluxPartyTextBandHeight,"pet appearance puts health text in its top band")
    check(member._fluxPartyHealthTextAnchor.points[1][4]==-member._fluxPartyHealthTextAnchor.points[2][4],"pet text margins are symmetric around frame X center")
    local namePetX=member._fluxPartyNameTextAnchor.points[1][4]
    e.pets[1]=false;refresh()
    check(member._fluxPartyHealthTextAnchor.point[1]=="BOTTOMRIGHT","without pet health text fills the bar for vertical centering")
    check(member._fluxPartyNameTextAnchor.points[1][4]==namePetX,"pet does not unnecessarily narrow the name header")
    e.targets[1]=true;refresh();check(P.targets[1].shown,"native state driver handles combat target acquisition")
    e.targets[1]=false;refresh();check(not P.targets[1].shown,"native state driver handles combat target loss")
    e.mode="raid";refresh();for _,f in ipairs(P.members)do check(not f.shown,"party mode hides immediately on combat raid conversion")end
    e.mode="solo";refresh();for _,f in ipairs(P.pets)do check(not f.shown,"all pet input rectangles disappear after combat group leave")end
    check(e.created==created,"roster changes in combat allocate no widgets")
    local writes=e.writes
    db.partyFrameScale=.7
    check(not P.ApplyOptions()and e.writes==writes and deferred["party.options"],"combat option edits defer protected work")
    e.combat=false;deferred["party.options"]()
    local raid=read("RaidFrame/FluxRaidUnit.lua")
    e.UnitOf=function(f)return f.unit end;e.IsSecret=e.issecretvalue
    e.ShowRegion=function(icon,v)if v then icon:Show()else icon:Hide()end end
    local first=assert(raid:find("local function SetCenterTexture",1,true));local last=assert(raid:find("function FluxRaid_UpdateRange",first,true))
    assert(load(raid:sub(first,last-1),"@party-raid-indicators","t",e))()
    e.GetReadyCheckStatus=function()return "ready"end
    e.UnitHasIncomingResurrection=function()return true end
    e.UnitGroupRolesAssigned=function()return "TANK"end
    e.mode,e.partyCount="party",1;refresh()
    local ancestor=member:GetParent();while ancestor do ancestor:Show();ancestor=ancestor:GetParent()end
    member.CastBar:Show()
    check(member.nameText.alpha==0 and member.levelText.alpha==0,"visible cast conceals name and level underneath")
    member.levelText:SetAlpha(1);P.LayoutIndicators(member)
    check(member.levelText.alpha==0,"metadata repaint cannot expose level over active cast")
    member.CastBar:Hide()
    check(member.nameText.alpha==1 and member.levelText.alpha==1,"cast end restores name and level")
    member.scripts.OnEvent(member,"READY_CHECK")
    check(member.readyCheckIcon.shown and member.partyRoleIcon.atlas=="roleicon-tiny-tank","actual raid ready-check and native role adapters paint party")
    member.scripts.OnEvent(member,"READY_CHECK_FINISHED")
    check(not member.readyCheckIcon.shown,"ready finish retires icon without a new ticker")
    e.UnitHasIncomingResurrection=function()return false end
    for _,mode in ipairs({"values","percent","both","none"})do
        db.partyHealthText,db.partyPowerText=mode,mode;P.ApplyTextModes(member)
        check(member.Health.Value.shown==(mode=="values"or mode=="both")and member.Power.Percent.shown==(mode=="percent"or mode=="both"),"independent display modes cover values/percent/both/hidden")
    end
    db.partyHealthText,db.partyPowerText="values","percent";P.ApplyTextModes(member)
    P.PaintStatus(member,"Offline");P.ApplyTextModes(member)
    check(not member.Health.Value.shown and not member.Health.Percent.shown and member.Power.Percent.shown,"status label replaces HP numbers without hiding resource percentage")
    P.PaintStatus(member,nil);P.ApplyTextModes(member)
    check(member.Health.Value.shown and not member.Health.Percent.shown,"status recovery restores chosen HP text mode")
    check(near(P.members[1].scale,194/(4*121)),"deferred scale applies outside combat")
    check(near(P.members[1].atlasBorderFrame.scale,P.members[1].scale)and near(P.pets[1].atlasBorderFrame.scale,P.members[1].scale),
        "detached atlas chrome matches owner and pet effective scale")
    db.partyShowPortrait=false;db.partyShowPets=false;db.strict=true;P.ApplyOptions()
    e.mode,e.partyCount="party",2;refresh()
    check(not P.members[1].PortraitFrame.shown and not P.pets[1].shown and P.members[1].lastStrict,"options preserve portraits/pets/filter ownership")
    check(P.members[2].point[4]==2,"portrait-off border retains the same right anchor")
    local bindings,casts=0,0
    for _,call in ipairs(calls)do if call[1]=="binding"then bindings=bindings+1 elseif call[1]=="cast"then casts=casts+1 end end
    check(bindings==12 and casts==4,"all eight live outer buttons join Flux binding/ClickCast and only members create cast bars")
    for _,f in ipairs(P.members)do check(e.ClickCastFrames[f.outerBorderFrame]and f.outerBorderFrame._fluxRaidUnit,"party casting registers the actual owned hit rectangle including primary-chord support")end
    e.FluxRaidPreview={PaintPartyAuras=function(f,i)f.sampleAuras=i end}
    P.RefreshPreview(true)
    for i,f in ipairs(P.preview.members)do
        check(f._fluxPartyPreview and f.noEvents and not f.outerBorderFrame.mouse and f.sampleAuras==i,
            "sample party reuses the component factory without live events, cast/binding registration or hit rectangles")
        check(f.width==260 and f.height==85 and f.scale==P.members[i].scale,
            "preview and live member geometry use identical dimensions and scale")
        check(f._fluxAuraLayer.level>f._fluxPartyIndicatorLayer.level,"preview auras share live portrait overlay ordering")
        check(P.preview.pets[i].width==60 and P.preview.pets[i].height==28,"preview pet uses the live pet component dimensions")
        check(f.Health.Value.text~="" and f.Power.Value.text~="","preview supplies real sample values for values and both modes")
        check((f.Health.color[1]==.5)==(i>1)and(f.Power.color[1]==.5)==(i>1),"preview HP/resource status colors agree with live policy")
    end
    check(near(P.preview.members[4].point[5]*P.preview.members[4].scale,P.members[4].point[5]*P.members[4].scale),
        "sample four-member preview uses the four-member dock bottom rather than the live two-member count")
    P.RefreshPreview(false);check(not P.preview.shown,"preview dismissal hides its own isolated tree")
    db.partyAsRaid=true;P.ApplyOptions();check(not P.ready,"style change relinquishes alternate mode")
    check(S.ConfigureHeader(header,1,false)and header.attrs.showParty==true,"return to original compact header leaves raid behavior intact")
    for _,f in ipairs(P.members)do check(not f.shown,"style switch hides alternate input rectangles")end
    -- Repeated cleanup catches the exact reported nil-method path even before
    -- alternate cells exist, with native restricted-only frame references.
    for i=1,8 do check(S.DisablePartyFrames(),"cleanup remains idempotent")end
    e.FluxOptions.GetUnitFrameDB=function()return {display={player={healthText="both"},pet={powerText=false}},healthPartitions={player=.7,pet=.8}}end
    assert(loadfile("UnitFrames/FluxUnitFrames_OptionsBridge.lua","t",e))("_FluxUI",ns)
    check(e.FluxUnitFrames_GetHealthPartitionPct("party1")==.7 and e.FluxUnitFrames_GetHealthPartitionPct("partypet1")==.8,
        "actual option bridge inherits player and pet bar proportions independently")
    check(e.FluxUnitFrames_GetHealthTextMode("party1")=="values"and not e.FluxUnitFrames_ShouldShowPowerText("partypet1"),
        "actual option bridge inherits player and pet text policies")
    db.partyShowCastBar=false
    check(not e.FluxUnitFrames_ShouldShowCastBar("party2")and not e.FluxUnitFrames_ShouldShowCastBar("partypet2"),"party cast toggle does not enable pet cast bars")
    db.partyAsRaid=false
    P.ApplyOptions();check(P.members[2].CastBar._fluxPetCastDisabled and not P.members[2].CastBar.shown,"cast toggle disables and hides live member cast bar")
    db.partyShowCastBar=true;e.activePartyCast=true;P.ApplyOptions()
    check(member.CastBar.shown and member.nameText.alpha==0 and member.levelText.alpha==0,"toggle on refreshes an already-active cast")
    db.partyShowCastBar=false;P.ApplyOptions()
    check(not member.CastBar.shown and member.nameText.alpha==1 and member.levelText.alpha==1,"toggle off restores covered labels immediately")
    e.activePartyCast=false
    db.partyAsRaid=true;P.ApplyOptions()
    check(not e.FluxUnitFrames_ShouldShowPortrait("party4")and not e.FluxUnitFrames_ShouldShowPortrait("partypet4"),"portrait control reaches every party token")
    e.RAID_CLASS_COLORS={MAGE={r=.2,g=.5,b=1}}
    local unitDB={};e.FluxOptions.GetUnitFrameDB=function()return unitDB end
    e.UnitIsPlayer=function()return true end;e.UnitClass=function()return "Mage","MAGE"end
    for _,unit in ipairs({"pettarget","focustarget","party1target"})do
        check(e.FluxUnitFrames_GetTargetClassHealthColor(unit)==nil,"target class HP opt-in defaults off")
        db.partyTargetClassColor=true;unitDB.classColorPetTargetHP=true;unitDB.classColorFocusTargetHP=true
        check(e.FluxUnitFrames_GetTargetClassHealthColor(unit)==.2,"targeting a player selects that player's class HP")
        e.UnitIsPlayer=function()return false end;check(e.FluxUnitFrames_GetTargetClassHealthColor(unit)==nil,"NPC target retains native HP color")
        e.UnitIsPlayer=function()return opaque end;check(e.FluxUnitFrames_GetTargetClassHealthColor(unit)==nil,"opaque player flag never selects a tint")
        e.UnitIsPlayer=function()return true end;e.UnitClass=function()return "Mage",opaque end
        check(e.FluxUnitFrames_GetTargetClassHealthColor(unit)==nil,"opaque class never indexes the static color table")
        e.UnitClass=function()return "Mage","MAGE"end
        db.partyTargetClassColor=false;unitDB.classColorPetTargetHP=false;unitDB.classColorFocusTargetHP=false
    end
    assert(loadfile("AddonOptions/FluxOptionsRaidFrame.lua","t",e))("_FluxUI",ns)
    local options=ns.FluxOptionsBuildPartyRaidTab().args.partyStyle.args
    check(options.partyAsRaid.get()and options.scale.disabled()and options.petScale.disabled(),"actual options default to compact and disable alternate style controls")
    local refreshes=0
    e.FluxOptions.RefreshRaidFrameScopedModules=function()refreshes=refreshes+1 end
    options.partyAsRaid.set(nil,false);options.scale.set(nil,.63);options.petScale.set(nil,.8)
    check(db.partyAsRaid==false and db.partyFrameScale==.63 and db.partyPetScale==.8 and refreshes==3 and not options.scale.disabled(),
        "actual style and scale setters use existing scoped refresh")
end
print("Party player-style frames: "..checks.." checks; five pinned secure handler models, combat roster/pet/anchor transitions; native visuals/input pending")
