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
    local function flushTimers()
        for pass=1,12 do
            if #timers==0 then return end
            local batch=timers;timers={};for _,fn in ipairs(batch)do fn()end
        end
        error("unbounded party timer chain")
    end
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
    function methods:SetClipsChildren(v)self.clipsChildren=v end
    function methods:SetReverseFill(v)self.reverseFill=v end
    function methods:SetMinMaxValues(a,b)self.minimum,self.maximum=a,b end
    function methods:GetMinMaxValues()return self.minimum,self.maximum end
    function methods:GetValue()return self.value end
    function methods:SetValue(v)self.value=v end
    function methods:SetStatusBarColor(...)self.color={...}end
    function methods:CreateTexture()
        return {SetAllPoints=function()end,SetTexture=function(s,v)s.texture=v end,SetVertexColor=function(s,...)s.color={...}end,
            SetTexCoord=function(s,...)s.uv={...}end,
            SetSize=function(s,w,h)s.width,s.height=w,h end,SetHeight=function(s,h)s.height=h end,
            SetColorTexture=function(s,...)s.color={...}end,SetPoint=function(s,...)s.point={...}end,
            ClearAllPoints=function(s)s.point=nil end,SetDrawLayer=function(s,l,n)s.layer,s.sublevel=l,n end,
            GetDrawLayer=function(s)return s.layer,s.sublevel end,GetSize=function(s)return s.width,s.height end,
            GetNumPoints=function(s)return s.point and 1 or 0 end,GetPoint=function(s)return table.unpack(s.point or {})end,
            SetAtlas=function(s,a,use)s.atlas=a;s.useAtlasSize=use end,
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
    ns.UnitFrames=UF; e.UF=UF
    local badgeSource=read(os.getenv("FLUX_PARTY_SHARED_SOURCE") or "UnitFrames/FluxUnitFrames_Shared.lua")
    local badgeStart=assert(badgeSource:find("local function PvpValueIsSecret",1,true))
    local badgeEnd=assert(badgeSource:find("function UF.CreateOuterBorder",badgeStart,true))
    assert(load(badgeSource:sub(badgeStart,badgeEnd-1),"@shared-pvp-badge","t",e))()
    local geometryStart=assert(badgeSource:find("do\nlocal function NameStripGeometryPublic",1,true))
    local geometryEnd=assert(badgeSource:find("--- Combat/rest beside level",geometryStart,true))
    assert(load(badgeSource:sub(geometryStart,geometryEnd-1),"@name-strip-native-geometry","t",e))()
    local styleStart=assert(badgeSource:find("    if (self._fluxPartyMember or self._fluxPartyPet or self._fluxCompactFocus)",geometryEnd,true))
    local styleEnd=assert(badgeSource:find("    -- Geometry skipped on combat entry",styleStart,true))
    local finishSharedText=assert(load("return function(self,deferPartyIndicators)\n"..
        badgeSource:sub(styleStart,styleEnd-1).."end","@shared-outer-style-handoff","t",e))()
    UF.CreateBaseFrame=function(unit,parent,w,h,_,options)
        calls[#calls+1]={"base",unit,w,h,options}
        local frame=e.CreateFrame("Button",options and options.name or "FluxUnitFrame_"..unit,parent)
        frame.unit=unit;frame.width,frame.height=w,h;frame._fluxPartyPreview=options and options.preview
        frame._fluxPreviewLayerParent=options and options.previewLayerParent
        if frame._fluxPreviewLayerParent then
            frame.SeparatorContainer=e.CreateFrame("Frame",nil,frame._fluxPreviewLayerParent)
        else frame:SetAttribute("unit",unit)end
        frame.UpdatePartition=function(s)calls[#calls+1]={"partition",s};s:UpdateOuterBorder()end
        frame.UpdateOuterBorder=function(s,deferPartyIndicators)
            calls[#calls+1]={"chrome",s}
            if s.classIcon then
                s.classIcon:SetSize(36,36);s.classIcon:SetPoint("TOPLEFT",s.outerBorderFrame,"TOPLEFT",0,-4);s.classIcon:Show()
                s.specIcon:SetPoint("TOPLEFT",s.classIcon,"TOPRIGHT",0,0)
            end
            finishSharedText(s,deferPartyIndicators)
        end
        return frame
    end
    UF.CreateHealthBar=function(f)f.Health=bar()end
    UF.CreatePowerBar=function(f)f.Power=bar()end
    UF.CreatePortrait=function(f)f.PortraitFrame=e.CreateFrame("Frame",nil,f);f.Portrait={}end
    UF.CreateAtlasBorder=function(f)f.atlasBorderFrame=e.CreateFrame("Frame",nil,f._fluxPreviewLayerParent or f)end
    UF.CreateOuterBorder=function(f)
        f.outerBorderFrame=e.CreateFrame("Button",nil,f);f.nameText=text();f.levelText=text();f.pvpTimer=text()
        for _,key in ipairs({"classIcon","specIcon","raidIcon","leaderIcon","assistantIcon","mainTankIcon","mainAssistIcon","masterLooterIcon"})do
            f[key]=f.outerBorderFrame:CreateTexture();f[key]:Hide()
        end
        UF.CreatePvpBadge(f)
    end
    UF.UpdateHealth=function(f)calls[#calls+1]={"health",f.unit}end
    UF.UpdatePower=function(f)calls[#calls+1]={"power",f.unit}end
    UF.UpdateBorderColors=function(f)calls[#calls+1]={"borderColors",f}end
    UF.UpdatePortrait=function(f,unit,roster)calls[#calls+1]={"portrait",unit,roster}end
    ns.CastBar={CreateCastBar=function(f,unit)
        f.CastBar=e.CreateFrame("Frame",nil,f);calls[#calls+1]={"cast",unit}
        f.CastBar.IconFrame=e.CreateFrame("Frame",nil,f.CastBar)
        local native=function()
            f.CastBar:SetPoint("LEFT",f.atlasBorderFrame,"RIGHT",0,0);f.CastBar:SetHeight(40)
            f.CastBar.IconFrame:SetSize(40,40)
        end
        f.CastBar.UpdateLayout=native;f.CastBar._nativeLayout=native
    end,ResetCastForUnit=function(bar)
        bar._resetCalls=(bar._resetCalls or 0)+1;bar:Hide()
    end,RefreshCastForUnit=function(bar,unit)
        bar._refreshCalls=(bar._refreshCalls or 0)+1
        calls[#calls+1]={"castRefresh",unit}
        if e.activePartyCast then bar:Show();bar.IconFrame:Show()else bar:Hide()end
    end}
    local ufSource=read("UnitFrames/FluxUnitFrames_Shared.lua")
    local a=assert(ufSource:find("function UF.LayoutRaidMarker",1,true));local b=assert(ufSource:find("function UF.UpdateOuterBorder",a,true))
    e.UF=UF;e.ValueIsSecret=function(v)return e.issecretvalue and e.issecretvalue(v)end
    e.CompactUnitFrame_OpenMenu=function()end
    local ma=assert(ufSource:find("function UF.ConfigureUnitMenu",1,true))
    local mb=assert(ufSource:find("-- Preserve the existing samples",ma,true))
    assert(load(ufSource:sub(ma,mb-1),"@shared-unit-menus","t",e))()
    e.PublicGeometryNumber=function(v)if e.ValueIsSecret(v) or type(v)~="number"then return nil end;return v end
    UF.RecordFrameDimensions=function(f,w,h)if w then f._fluxLayoutWidth=w end;if h then f._fluxLayoutHeight=h end end
    UF.GetFramePublicDimensions=function(f)return f._fluxLayoutWidth or f.width or f:GetWidth(),f._fluxLayoutHeight or f.height or f:GetHeight()end
    e.StatusBarSetMinMaxImmediate=function(b,a,z)b:SetMinMaxValues(a,z)end
    e.StatusBarSetValueImmediate=function(b,v)b:SetValue(v)end
    e.ApplyBlizzardShieldFillToStatusBar=function(b)b:SetStatusBarColor(.14,.33,.7,.7)end
    e.ApplyBlizzardHealAbsorbFillToStatusBar=function(b)b:SetStatusBarColor(.68,.28,.28,.7)end
    e.API={SafeUnitGetTotalAbsorbs=function()return 0 end,SafeUnitGetTotalHealAbsorbs=function()return 0 end,
        IsSecretValue=function(value)return e.issecretvalue and e.issecretvalue(value)end}
    e.FluxSafeRegisterUnitEvent=function(frame,event,unit)frame:RegisterUnitEvent(event,unit)end
    local va=assert(ufSource:find("function UF.LayoutVerticalTargetHealth",1,true))
    local vb=assert(ufSource:find("function UF.UpdateHealth(self, unit)",va,true))
    assert(load(ufSource:sub(va,vb-1),"@shared-vertical-target-health","t",e))()
    assert(load(ufSource:sub(a,b-1),"@shared-player-raid-marker","t",e))()
    local sepFirst=assert(ufSource:find("local function CreateSeparator(parent)",1,true))
    local sepLast=assert(ufSource:find("local AnimatedHealthLossMixin",sepFirst,true))
    assert(load(ufSource:sub(sepFirst,sepLast-1),"@shared-target-divider","t",e))()
    e.FluxRaidAuras={Setup=function(f)calls[#calls+1]={"auras",f.unit}end,Refresh=function()end,
        Update=function(f)f.lastStrict=f.optionTable.displayOnlyDispellableDebuffs end,Clear=function()end}
    local states={}
    local originalRegister=ns.Flux.Restricted.RegisterPagingDriver
    local originalUnregister=ns.Flux.Restricted.UnregisterPagingDriver
    e.SecureCmdOptionParse=assert(loadfile("tests/support/group_condition_parser.lua"))()({
        exists=function(token)
            if token:match("^raid%d+$")then return e.mode=="raid"end
            local index=tonumber(token:match("(%d+)"))
            return index and index<=e.partyCount and(not token:match("^partypet")or e.pets[index])and(not token:match("target$")or e.targets[index])
        end,
        petbattle=function()return e.petbattle end,group=function()return e.mode end,
    })
    local function refresh()
        secure(function()for owner,list in pairs(states)do for state,condition in pairs(list)do e.resolveDriver(owner,"state-"..state,condition)end end end)
    end
    ns.Flux.Restricted.RegisterPagingDriver=function(owner,state,condition)
        if state=="visibility"or state=="petlayout"or state=="partygroup"then
            assert(not e.combat);states[owner]=states[owner]or{};states[owner][state]=condition;refresh();return true
        end
        return originalRegister(owner,state,condition)
    end
    ns.Flux.Restricted.UnregisterPagingDriver=function(owner,state)
        if state=="visibility"or state=="petlayout"or state=="partygroup"then assert(not e.combat);if states[owner]then states[owner][state]=nil end;return true end
        return originalUnregister(owner,state)
    end
    e.pets={};e.targets={}
    e.UnitHealth=function()return 80 end;e.UnitHealthMax=function()return 100 end;e.UnitIsConnected=function()return true end
    assert(loadfile(os.getenv("FLUX_PARTY_FRAME_SOURCE") or "UnitFrames/FluxUnitFrames_Party.lua","t",e))("_FluxUI",ns)
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
    for i=1,4 do
        check(P.members[i]._FluxBorderIndependent and P.pets[i]._FluxBorderIndependent and P.targets[i]._FluxBorderIndependent,
            "live party/member pet/target factories opt into independent border scopes")
    end
    check(member._fluxPartyPvpLayer.level<member._fluxPartyIndicatorLayer.level,"native PvP badge is behind the level layer")
    e.GetPVPTimer=function()error("another member must never use the player's PvP timer")end
    e.UnitIsPVPFreeForAll=function()return false end;e.UnitIsPVP=function()return true end
    e.UnitFactionGroup=function()return "Horde"end
    e.UnitFrameUtil=nil;e.C_Texture=nil
    P.UpdatePvpBadge(member)
    check(member.pvpIcon.width==64 and member.pvpIcon.height==64 and member.pvpIcon.texture=="Interface\\TargetingFrame\\UI-PVP-Horde",
        "legacy uses the client's full64x64 faction badge")
    check(member.pvpIcon.point[2]==member.levelText and member.pvpTimer.points[1][2]==member.levelText
        and member.pvpTimer.points[1][3]=="BOTTOM"and not member.pvpTimer.shown,"badge behind level and empty timer slot below it")
    e.UnitIsPVPFreeForAll=function()return true end;P.UpdatePvpBadge(member)
    check(member.pvpIcon.texture=="Interface\\TargetingFrame\\UI-PVP-FFA","native legacy FFA art retained")
    e.UnitIsPVPFreeForAll=function()return opaque end;P.UpdatePvpBadge(member)
    check(not member.pvpIcon.shown,"fallback cannot branch on opaque PvP flags")
    local delegates=0
    e.UnitFrameUtil={UpdateUnitPvPIndicator=function(elements,unit,mercenary)
        delegates=delegates+1;check(unit=="party1"and mercenary==false,"native PvP renderer receives actual party token")
        elements.pvpIcon:SetAtlas("native-client-pvp",true);elements.pvpIcon:Show()
    end}
    P.UpdatePvpBadge(member)
    check(delegates==1 and member.pvpIcon.useAtlasSize,"modern path uses native renderer/atlas dimensions despite opaque flags")
    check(member._fluxPartyPrestigePortrait.width==50 and member._fluxPartyPrestigePortrait.height==52
        and member._fluxPartyPrestigeBadge.width==30,"prestige textures retain native player XML dimensions")
    e.UnitFrameUtil=nil;e.UnitIsPVPFreeForAll=function()return false end;e.UnitIsPVP=function()return false end
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
    e.FluxRaidState.containerFrame:Hide()
    e.combat=true
    for count=1,4 do
        e.mode,e.partyCount="party",count;e.pets[count]=true;refresh()
        check(e.FluxRaidState.containerFrame:IsShown(),"native party state reveals the hidden prepared parent in combat")
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
    -- The shared header fixture treats every visual child as protected.
    -- Model secure visibility under lockdown and exercise paint outside it.
    e.combat=false;flushTimers();e.combat=true
    local target=P.targets[1]
    local targetPaints,targetResets=0,0
    local updateTarget,resetTarget=UF.UpdateVerticalTargetHealth,UF.ResetVerticalTargetHealth
    UF.UpdateVerticalTargetHealth=function(f,unit,rosterRefresh)
        if f==target then targetPaints=targetPaints+1 end
        return updateTarget(f,unit,rosterRefresh)
    end
    UF.ResetVerticalTargetHealth=function(f)
        if f==target then targetResets=targetResets+1 end
        return resetTarget(f)
    end
    local function NotifyPartyRoster(frame)
        if P.QueueRosterUpdate then
            P.QueueRosterUpdate()
        else
            frame.scripts.OnEvent(frame,"GROUP_ROSTER_UPDATE")
        end
    end
    e.targets[1]=true;refresh();check(target.shown,"native state driver handles combat target acquisition")
    for _=1,20 do NotifyPartyRoster(target) end
    check(targetPaints==0 and targetResets==(P.QueueRosterUpdate and 0 or 1),
        "party-target roster burst defers the visual paint during the native reveal")
    e.combat=false
    flushTimers()
    check(targetPaints==1 and targetResets==1,"party-target roster burst resets identity and paints its current visible state once")
    target.scripts.OnEvent(target,"UNIT_TARGET")
    check(targetPaints==2 and targetResets==2,"a direct target change still paints and resets immediately")
    e.combat=true
    for i=1,4 do check(P.targets[i].width==30 and P.targets[i].height==121,"party target keeps prepared narrow size through combat roster changes")end
    e.targets[1]=false;refresh();check(not P.targets[1].shown,"native state driver handles combat target loss")
    NotifyPartyRoster(target)
    -- Its owner is still visible and will receive the broader roster paint.
    -- The synthetic helper treats the decorative children as protected.
    e.combat=false;flushTimers();e.combat=true
    check(targetPaints==2 and targetResets==3,"hidden party target clears through OnHide and skips subsequent roster work")
    UF.UpdateVerticalTargetHealth,UF.ResetVerticalTargetHealth=updateTarget,resetTarget
    local rangeChecks=0
    e.FluxRaid_EnsureRangePoll=function()rangeChecks=rangeChecks+1 end
    e.mode="raid";refresh();for _,f in ipairs(P.members)do check(not f.shown,"party mode hides immediately on combat raid conversion")end
    check(rangeChecks==0,"party retirement books range reconciliation into the shared batch")
    flushTimers()
    check(rangeChecks==1,"party and pet retirement reconcile range once regardless of hidden slots")
    e.FluxRaid_EnsureRangePoll=nil
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
    local resets=member.CastBar._resetCalls or 0
    member:Hide()
    check(member.CastBar._resetCalls==resets+1,"owner hide releases cast lifecycle through the shared reset")
    flushTimers()
    local refreshes=member.CastBar._refreshCalls or 0
    member:Show();flushTimers()
    check(member.CastBar._refreshCalls==refreshes+1,"owner show reads the current cast after secure visibility dispatch")
    resets=member.CastBar._resetCalls;refreshes=member.CastBar._refreshCalls
    for _=1,20 do NotifyPartyRoster(member) end
    check(member.CastBar._resetCalls==resets and member.CastBar._refreshCalls==refreshes,"roster burst postpones duplicate cast/portrait paints to one batch")
    flushTimers()
    check(member.CastBar._resetCalls==resets+1 and member.CastBar._refreshCalls==refreshes+1,"roster slot update resets old cast and samples its current member")
    local guid = "party-member-a"
    e.UnitGUID = function(unit) if unit == member.unit then return guid end end
    local function rosterCast()
        NotifyPartyRoster(member)
        flushTimers()
    end
    do
        guid = "party-indicator-member"
        member.leaderIcon:Show()
        member.mainTankIcon:Show()
        rosterCast()
        local work={styles=0,layouts=0,roleWrites=0}
        local style,layout=P.StyleText,P.LayoutIndicators
        P.StyleText=function(frame,...)
            if frame==member then work.styles=work.styles+1 end
            return style(frame,...)
        end
        P.LayoutIndicators=function(frame,...)
            if frame==member then work.layouts=work.layouts+1 end
            return layout(frame,...)
        end
        for _,icon in ipairs({member.leaderIcon,member.mainTankIcon,member.partyRoleIcon}) do
            for _,method in ipairs({"ClearAllPoints","SetPoint","SetSize","SetDrawLayer"}) do
                local write=icon[method]
                icon[method]=function(self,...)
                    work.roleWrites=work.roleWrites+1
                    return write(self,...)
                end
            end
        end
        for _=1,4 do
            for _=1,20 do NotifyPartyRoster(member) end
            flushTimers()
        end
        print(("PARTY_INDICATOR_WORK|%s|%d|%d|%d"):format(client,work.styles,work.layouts,work.roleWrites))
        check(work.styles==4 and work.layouts==4 and work.roleWrites==0,
            "one text and indicator pass per settled roster burst, with no unchanged role writes")
        check(member.partyRoleIcon.point[2]==member.PortraitFrame and member.partyRoleIcon.layer=="OVERLAY"
            and member.partyRoleIcon.sublevel==7,"settled role art stays at its owned portrait position and depth")
        local tank=member.mainTankIcon
        member.leaderIcon:Hide()
        tank:SetSize(44,36);tank:SetDrawLayer("ARTWORK",1)
        rosterCast()
        check(tank.point[4]==2 and tank.point[5]==-1 and tank.width==22 and tank.height==18
            and tank.layer=="OVERLAY" and tank.sublevel==7,"role changes repack and repair current size and depth")
        local get=tank.GetPoint
        tank.GetPoint=function()return "TOPLEFT",opaque,"TOPLEFT",2,-1 end
        work.roleWrites=0
        rosterCast()
        check(work.roleWrites>=2 and tank.point[2]==member.PortraitFrame,
            "unreadable role anchor uses the original placement")
        tank.GetPoint=get
        P.StyleText,P.LayoutIndicators=style,layout
        guid = "party-member-a"
    end
    e.activePartyCast = true
    rosterCast()
    resets, refreshes = member.CastBar._resetCalls, member.CastBar._refreshCalls
    check(member.CastBar.shown,"a newly observed member can start with an active cast")
    for _=1,20 do rosterCast() end
    check(member.CastBar._resetCalls==resets and member.CastBar._refreshCalls==refreshes and member.CastBar.shown,
        "confirmed unchanged member keeps active cast through roster changes")
    guid, e.activePartyCast = "party-member-b", false
    rosterCast()
    check(member.CastBar._resetCalls==resets+1 and member.CastBar._refreshCalls==refreshes+1 and not member.CastBar.shown,
        "same party token must refresh immediately when the member changes")
    local opaqueGuid, existingSecret = {}, e.issecretvalue
    guid = opaqueGuid
    e.issecretvalue = function(value) return rawequal(value,opaqueGuid) or existingSecret and existingSecret(value) end
    rosterCast()
    rosterCast()
    check(member.CastBar._resetCalls==resets+3 and member.CastBar._refreshCalls==refreshes+3,
        "private member identity keeps the conservative refresh path")
    e.issecretvalue = existingSecret
    guid = "party-member-b"
    rosterCast()
    refreshes = member.CastBar._refreshCalls
    member:Hide();member:Show();flushTimers()
    check(member.CastBar._refreshCalls==refreshes+1,"a previously hidden member samples its current cast regardless of identity")
    e.UnitGUID = nil
    local rosterPortrait
    for _, call in ipairs(calls) do
        if call[1] == "portrait" and call[2] == member.unit then rosterPortrait = call[3] end
    end
    check(rosterPortrait == true, "queued roster paint opts into validated portrait reuse")
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
    for _,pet in ipairs(P.preview.pets)do
        local painted=false
        for _,call in ipairs(calls)do if call[1]=="borderColors" and call[2]==pet then painted=true;break end end
        check(painted,"preview pets use their unit/owner border-color painter")
    end
    for i,f in ipairs(P.preview.members)do
        check(f._FluxBorderIndependent and P.preview.pets[i]._FluxBorderIndependent and P.preview.targets[i]._FluxBorderIndependent,
            "preview members use the same independent border contract as live members")
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
    local world, pane = P.preview, e.CreateFrame("Frame",nil,e.UIParent)
    pane:SetScale(.85)
    local inline = assert(P.CreateOptionsPreview(pane))
    check(inline.parent==pane and not inline.shown and not inline.name,"settings tree starts hidden in its own unnamed root")
    check(#inline.members==4 and inline:Refresh(360,280) and near(inline.scale,1),"wide settings pane fits all four world-scale members")
    for i, frame in ipairs(inline.members) do
        local original, pet, target = world.members[i], inline.pets[i], inline.targets[i]
        check(frame.parent==inline and frame.atlasBorderFrame.parent==inline and frame.SeparatorContainer.parent==inline
            and frame._fluxPartyThreat.parent==inline,"all detached settings chrome follows the settings lifetime")
        check(frame.width==original.width and frame.height==original.height and near(frame.scale,original.scale)
            and near(frame.atlasBorderFrame.scale,original.scale) and near(frame._fluxPartyThreat.scale,original.scale),
            "settings use the same member geometry without double-scaling detached chrome")
        check(frame.nameText.text==original.nameText.text and frame.Health.value==original.Health.value
            and frame.Health.Value.text==original.Health.Value.text and frame.Power.Percent.text==original.Power.Percent.text
            and frame.Health.color[1]==original.Health.color[1] and near(frame.alpha,original.alpha)
            and frame._fluxPartyStatusText==original._fluxPartyStatusText and frame.sampleAuras==original.sampleAuras,
            "shared preview painter preserves sample names, health, resources, status, opacity and aura selection")
        check(pet.shown==world.pets[i].shown and pet.Health.value==world.pets[i].Health.value
            and target.shown==world.targets[i].shown and target.HealthBar.value==world.targets[i].HealthBar.value,
            "pet and target paints match the world preview")
        check(frame.noEvents and not frame.attrs.unit and not frame.outerBorderFrame.mouse
            and not e.ClickCastFrames[frame.outerBorderFrame] and not frame.CastBar,
            "settings preview registers no roster events, unit attributes, clicks or cast owner")
    end
    local work = {layout = 0, outer = 0, chrome = 0, pet = 0, model = 0, slot = 0, fit = 0, threat = 0, text = 0, aura = 0}
    local restore = {}
    local function count(t, method, field, include)
        local previous = t[method]
        t[method] = function(owner, ...)
            if not include or include(owner) then work[field] = work[field] + 1 end
            return previous(owner, ...)
        end
        restore[#restore + 1] = function() t[method] = previous end
    end
    count(P, "PaintChrome", "chrome")
    count(P, "StyleText", "text")
    count(P, "SetThreatColor", "threat")
    count(UF, "UpdateBorderColors", "pet")
    count(UF, "UpdatePortrait", "model")
    count(e.FluxRaidPreview, "PaintPartyAuras", "aura")
    count(methods, "SetPoint", "slot", function(f) return f._fluxPartyMember end)
    count(methods, "SetPoint", "fit", function(f) return f == inline end)
    count(methods, "SetSize", "layout", function(f) return f._fluxPartyMember end)
    for _, frames in ipairs({inline.members, inline.pets}) do
        for _, frame in ipairs(frames) do count(frame, "UpdateOuterBorder", "outer") end
    end
    local oldHealth = db.partyHealthText
    for edit = 1, 24 do
        local mode = edit % 2 == 0 and "values" or "percent"
        db.partyHealthText = mode
        check(inline:Refresh(360, 280) and inline.members[1].Health.Value.shown == (mode == "values"),
            "paint-only edits still update the visible health text mode")
    end
    check(work.layout == 0 and work.outer == 0 and work.chrome == 0 and work.pet == 0 and work.model == 0
        and work.slot == 0 and work.fit == 0 and work.threat == 0 and work.text == 0 and work.aura == 96,
        "24 paint-only edits skip unchanged fit, layouts, chrome and portraits while keeping aura paints")
    print("PARTY_EDIT_WORK|" .. table.concat({client, work.layout, work.outer, work.chrome, work.pet, work.model,
        work.slot, work.fit, work.threat, work.text, work.aura}, "|"))
    local oldClass, oldPortrait, oldWidth = db.partyClassColor, db.partyShowPortrait, db.partyWidthScale
    db.partyClassColor = not oldClass
    check(inline:Refresh(360, 280) and work.chrome == 4 and work.pet == 4 and work.layout == 0,
        "class accents repaint chrome without moving member geometry")
    db.partyShowPortrait = true
    check(inline:Refresh(360, 280) and work.model == 4 and work.layout == 4,
        "enabling portraits lays out the slots and binds the model once")
    e.FluxUnitFrames_ShouldUse3DPortrait = function() return false end
    check(inline:Refresh(360, 280) and work.model == 8 and work.layout == 4,
        "switching portrait mode repaints model artwork without structural layout")
    db.partyWidthScale = .9
    check(inline:Refresh(360, 280) and inline.members[1].width == 293 and work.layout == 8 and work.model == 8,
        "resizing a frame updates actual member geometry without rebinding the portrait")
    db.partyHealthText, db.partyClassColor, db.partyShowPortrait, db.partyWidthScale = oldHealth, oldClass, oldPortrait, oldWidth
    e.FluxUnitFrames_ShouldUse3DPortrait = nil
    for i = #restore, 1, -1 do restore[i]() end
    check(inline:Refresh(360, 280), "restore the previous sample settings")
    local allocations = e.created
    check(inline:Refresh(125,110) and inline.scale<1 and e.created==allocations,"narrow resizing scales and reuses the same preview tree")
    check(near(inline.members[1].atlasBorderFrame.scale,world.members[1].scale),
        "fitting applies one uniform scale to members and detached chrome")
    inline:Hide()
    check(world.shown and not inline.shown and P.preview==world,"closing settings does not hide or replace the world preview")
    check(inline:Refresh(360,280) and e.created==allocations,"reopening reuses the settings tree")
    P.RefreshPreview(false);check(not P.preview.shown,"preview dismissal hides its own isolated tree")
    check(inline.shown,"closing the world preview does not close its settings counterpart")
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
    -- Build the real focus initializer on the same component fixture. It must
    -- share presentation without registering as a party member or raid aura.
    local initializers={}
    UF.RegisterInitializer=function(unit,fn)initializers[unit]=fn end
    UF.DeferProtected=function(key,fn)deferred[key]=fn end
    UF.SyncWatchedUnitFrameVisibility=function(f)f:Show()end
    UF.GetFluxStylePartitionHealthHeight=function(h)return h*.6 end
    UF.CreateMouseoverHighlight=function(f)return e.CreateFrame("Frame",nil,f)end
    e.FLUX_API={hasFocusUnit=true}
    e.UnitExists=function()return true end
    e.FluxUnitFrames_ShouldUseFlux=function()return true end
    e.FluxUnitFrames_SuppressBlizzardUnitFrame=function()end
    e.GetRaidTargetIndex=function()return nil end
    UF.ApplyAuraOptionsToFrame=function(f)
        f.BuffContainer=e.CreateFrame("Frame",nil,f)
        f.DebuffContainer=e.CreateFrame("Frame",nil,f)
    end
    assert(loadfile("UnitFrames/FluxUnitFrames_Focus.lua","t",e))("_FluxUI",ns)
    initializers.focus()
    local focus=ns.FocusFrame
    check(focus._fluxCompactFocus and not focus._fluxPartyMember and focus.portraitPosition=="LEFT" and focus.outerBorderPadding==36,
        "focus gets party presentation without joining party roster/visibility")
    check(focus.width==260 and focus.height==85 and near(focus.scale,P.GetScale()),"focus default body matches normal party design box and scale")
    check(focus.BuffContainer and focus.DebuffContainer and not focus._fluxAuraLayer and near(focus.BuffContainer.scale,1/P.GetScale()),
        "focus keeps external aura panels at existing screen size rather than party in-frame auras")
    check(near(focus._fluxFocusAuraPanelScale,1/P.GetScale()) and focus.BuffContainer.level>focus._fluxPartyIndicatorLayer.level
        and focus.BuffContainer.level<focus.CastBar.level,"focus aura geometry uses panel scale and artwork sits above indicators/below casts")
    check(focus._fluxPartyDivider and focus._fluxPartyIndicatorLayer and focus._fluxPartyNameTextAnchor,
        "focus reuses party divider and independent text/status layers")
    local hudClient = client == "live" or client == "forever"
    if hudClient then focus.Health._fluxTextAnchor = e.CreateFrame("Frame", nil, focus.Health) end
    P.LayoutFocusPresentation(focus)
    local healthBand = focus.Health._fluxTextAnchor or focus.Health
    check(focus._fluxPartyHealthTextAnchor.points[1][2] == healthBand
        and focus._fluxPartyHealthTextAnchor.points[2][2] == healthBand,
        "compact Focus text stays within the HUD health band and falls back to the Classic bar")
    check(focus._fluxPartyPowerTextAnchor.points[1][2] == focus.Power
        and focus._fluxPartyPowerTextAnchor.points[2][2] == focus.Power,
        "compact Focus power labels use the independent resource band")

    local previewFocus = UF.CreateBaseFrame("focus", pane, 260, 85, nil, {previewLayerParent = pane})
    previewFocus._fluxIndividualPreview, previewFocus._fluxCompactFocus = true, true
    previewFocus:SetScale(.42)
    UF.CreateHealthBar(previewFocus)
    UF.CreatePowerBar(previewFocus)
    UF.CreateOuterBorder(previewFocus)
    UF.CreateAtlasBorder(previewFocus)
    if hudClient then previewFocus.Health._fluxTextAnchor = e.CreateFrame("Frame", nil, previewFocus.Health) end
    local registrations, chromePaints = 0, 0
    previewFocus.RegisterEvent = function() registrations = registrations + 1 end
    local paintChrome = P.PaintChrome
    P.PaintChrome = function(frame, ...) chromePaints = chromePaints + 1; return paintChrome(frame, ...) end
    P.SetupFocusPresentation(previewFocus)
    P.PaintChrome = paintChrome
    check(registrations == 0 and chromePaints == 0 and not previewFocus:GetScript("OnEvent"),
        "compact Focus preview never joins live event or chrome painters")
    check(previewFocus._fluxPartyDivider
        and previewFocus._fluxPartyHealthTextAnchor.points[1][2] == (previewFocus.Health._fluxTextAnchor or previewFocus.Health)
        and near(previewFocus.atlasBorderFrame.scale, .42) and near(previewFocus.SeparatorContainer.scale, .42),
        "compact Focus preview adopts the real text band, divider, and its pane-relative scale")
    check(focus.CastBar._fluxCompactOverlay and focus.CastBar.level==150 and focus.CastBar.point[3]=="TOPRIGHT",
        "focus cast occupies the same raised compact header")
    local focusAncestor=focus;while focusAncestor do focusAncestor:Show();focusAncestor=focusAncestor:GetParent()end
    focus.CastBar:Hide();focus.CastBar:Show();check(focus.nameText.alpha==0 and focus.levelText.alpha==0,"focus cast covers name/level")
    focus.CastBar:Hide();check(focus.nameText.alpha==1 and focus.levelText.alpha==1,"focus cast restores name/level")
    assert(loadfile("UnitFrames/FluxUnitFrames_FocusTarget.lua","t",e))("_FluxUI",ns)
    initializers.focustarget()
    local ft=ns.FocusTargetFrame
    check(ft._fluxVerticalFocusTarget and ft.Health.orientation=="VERTICAL" and not ft.atlasBorderFrame,
        "focus target is HP-only vertical bar without horizontal atlas chrome")
    check(ft.width==30 and ft.height==121 and ft.point[2]==focus.outerBorderFrame and ft.point[3]=="TOPRIGHT",
        "focus target matches party target dimensions and right-edge anchor")
    check(ft.Health.Percent.alpha==0 and ft.Health.Value.alpha==0,"vertical target omits party-target labels")
    local initialWidth=ft.width;e.combat=true;focus.height=100;e.FluxUnitFrames_MatchFocusTargetToFocus()
    check(ft.width==initialWidth and ft.height==121 and deferred["focustarget.metrics"],"combat keeps prepared target geometry and defers full metrics")
    e.combat=false;e.FluxUnitFrames_MatchFocusTargetToFocus()
    check(ft.height==136,"focus sizing applies target geometry outside combat")
    focus.height=85
    local userScale=e.FluxUnitFrames_GetWholeFrameScale("focus")
    check(near(userScale,1) and near(e.FluxUnitFrames_GetFocusPresentationScale(),P.GetScale()),"focus user scale remains1 separately from party baseline")

end
print("Party player-style frames: "..checks.." checks; five pinned secure handler models, combat roster/pet/anchor transitions; native visuals/input pending")
