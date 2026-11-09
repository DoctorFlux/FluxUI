-- Production adjunct logic and secure state snippets under desktop contracts.
-- These checks do not certify the native driver engine, pixels or taint.
local function read(path)
    local f=assert(io.open(path,"rb")); local value=f:read("*a"):gsub("\r\n","\n"); f:close(); return value
end
local source=read("RaidFrame/FluxRaidHealerExtras.lua")
local checks=0
local function check(ok,why) checks=checks+1; assert(ok,why) end
local function fixture(client, body)
    local e=setmetatable({},{__index=_G}); e._G=e
    local db={showMissingClassBuffs=true}
    local ns={Flux={}}
    e.combat,e.secure,e.enabled,e.support,e.restricted=false,false,true,true,false
    e.auraQueries,e.mutations,e.cellCount,e.paintCount=0,0,0,0
    e.class="PRIEST"
    e.secret=setmetatable({},{__index=function()error("secret table dereferenced")end})
    e.inaccessible=setmetatable({},{__index=function()error("inaccessible table dereferenced")end})
    e.UnitClass=function()return "Priest",e.class end
    e.InCombatLockdown=function()return e.combat end
    e.FluxRaid_IsFluxRaidEnabled=function()return e.enabled end
    e.FluxOptions={GetRaidFrameDB=function()return db end,RefreshRaidFrameScopedModules=function()e.changes=(e.changes or 0)+1 end}
    e.FluxRaidCompat={IsSecret=function(v)return v==e.secret end}
    e.FluxRaidState={frameArray={}}
    local units={player={auras={},mana=0},party1={auras={},mana=0},party2={auras={},mana=1}}
    e.UnitExists=function(unit)return units[unit] and (e.existsResult or true) or false end
    e.UnitIsConnected=function()return true end
    e.UnitIsDeadOrGhost=function()return false end
    e.UnitIsPlayer=function()return true end
    e.UnitIsUnit=function(a,b)return a==b end
    e.UnitPowerType=function(unit)return units[unit] and units[unit].mana end
    e.UnitGroupRolesAssigned=function()return "HEALER" end
    local names={[1243]="Fortitude",[21562]="Prayer of Fortitude",[14752]="Spirit",[27681]="Prayer of Spirit",
        [976]="Shadow Protection",[27683]="Prayer of Shadow Protection",[588]="Inner Fire",[1459]="Intellect",[23028]="Brilliance"}
    e.known={[1243]=true,[14752]=true,[976]=true,[588]=true}
    e.IsSpellKnown=function(id)return e.known[id] or false end
    ns.Flux.Spell={GetInfo=function(id)return names[id],nil,names[id] and (id+100) end}
    ns.Flux.Secrets={AurasRestricted=function()return e.restricted end,CanAccessTable=function(value)return value~=e.inaccessible end}
    local function aura(unit,index)
        e.auraQueries=e.auraQueries+1
        if e.auraFailure then error("unavailable aura API") end
        if e.auraOverride then return e.auraOverride end
        return units[unit].auras[index]
    end
    if client=="classic_era" then
        e.UnitAura=function(unit,index) local a=aura(unit,index); return a and a.name end
    else e.C_UnitAuras={GetAuraDataByIndex=aura} end
    local methods={}
    local function legal()assert(not e.combat or e.secure,"insecure protected mutation during combat");e.mutations=e.mutations+1 end
    local function region(parent,protected)
        return setmetatable({parent=parent,protected=protected,attrs={},points={},shown=true,events={},children={}},{__index=methods})
    end
    function methods:CreateTexture()assert(not e.combat);return region(self,false)end
    function methods:SetTexture(v)self.texture=v end
    function methods:SetSize(w,h)if self.protected then legal()end;self.width,self.height=w,h end
    function methods:SetTexCoord(...)self.texcoord={...}end
    function methods:SetAlpha(v)self.alpha=v end
    function methods:SetPoint(...)if self.protected then legal()end;self.points[#self.points+1]={...}end
    function methods:ClearAllPoints()if self.protected then legal()end;self.points={}end
    function methods:Show()if self.protected then legal()end;self.shown=true end
    function methods:Hide()if self.protected then legal()end;self.shown=false end
    function methods:IsShown()return self.shown end
    function methods:SetAttribute(k,v)legal();self.attrs[k]=v end
    function methods:GetAttribute(k)return self.attrs[k]end
    function methods:SetScript(k,v)self[k]=v end
    function methods:RegisterEvent(event)self.events[event]=true end
    function methods:UnregisterAllEvents()self.events={}end
    e.allFrames={}
    e.CreateFrame=function(kind,name,parent,template)
        if template then legal();e.cellCount=e.cellCount+1 end
        local f=region(parent,template~=nil);f.name,f.template=name,template
        e.allFrames[#e.allFrames+1]=f
        if name then e[name]=f end
        if template then
            f._fluxRaidUnit=true
            f.healthBar=region(f,false)
            e.FluxRaidState.frameArray[f]=f
            f.bindingRegistered=true -- FluxRaidUnitTemplate owns registration.
        end
        return f
    end
    e.FluxRaidState.containerFrame=region(nil,true)
    e.FluxRaidState.containerFrame.width=592
    e.FluxRaidVisuals={FRAME_WIDTH=72,FRAME_HEIGHT=43,ApplyCellChrome=function(f,opts)f.chrome=opts end}
    e.FluxRaid_BindUnit=function(f,unit)f.unit=unit end
    e.FluxRaid_PaintUnit=function()e.paintCount=e.paintCount+1 end
    ns.Flux.Restricted={PagingWorks=function()return e.support end,
        SetPagingSnippet=function(f,key,code)f:SetAttribute(key,code);return true end,
        RegisterPagingDriver=function(f,state,condition)legal();f.driver={state=state,condition=condition};return true end,
        UnregisterPagingDriver=function(f)legal();f.driver=nil;return true end}
    assert(load(body or source,"@FluxRaidHealerExtras","t",e))("_FluxUI",ns)
    local extras=e.FluxRaidHealerExtras
    local function cell(unit,mini)
        local f=region(nil,true);f.unit=unit;f._fluxRaidMini=mini;f.healthBar=region(f,false)
        extras.Setup(f);return f
    end
    local function shown(f)local n=0;for _,icon in ipairs(f._fluxMissingBuffIcons or {})do if icon.shown then n=n+1 end end;return n end
    return e,db,extras,cell,shown,units,ns
end

local function exercise(client,body)
    local e,db,E,cell,shown,units,ns=fixture(client,body)
    local member,self=cell("party1")
    local ids,names=E.GetClassBuffFilter()
    check(ids[10938]and ids[21564]and ids[32999]and names.Fortitude and names["Prayer of Spirit"],
        client..": class filter covers rank/group IDs and localized family names regardless caster")
    local sameIDs,sameNames=E.GetClassBuffFilter()
    check(sameIDs==ids and sameNames==names,client..": class filter returns stable cached maps")
    E.Update(member)
    check(shown(member)==3,client..": three learned class buffs are marked missing")
    for _,icon in ipairs(member._fluxMissingBuffIcons)do check(icon.alpha==0.4 and icon.points[1][1]=="BOTTOMRIGHT","missing marks are dim corner textures")end
    units.party1.auras={{name="Prayer of Fortitude"}}
    E.Update(member)
    check(shown(member)==2,client..": group buff variant satisfies its class-buff category")
    local physical=cell("party2");E.Update(physical)
    check(shown(physical)==2,client..": mana-only buff is not suggested for physical resource")
    self=cell("player");E.Update(self)
    check(shown(self)==3,client..": self-only buffs respect the maximum of three marks")
    local mini=cell("party1",true);E.Update(mini)
    check(not mini._fluxMissingBuffIcons,client..": half-height minis have no missing-buff adornments")
    local queries=e.auraQueries
    e.combat=true;E.OnEvent("PLAYER_REGEN_DISABLED");E.Update(member)
    check(shown(member)==0 and e.auraQueries==queries,client..": combat immediately clears marks and never scans buffs")
    e.combat=false;e.restricted=true;E.Update(member)
    check(shown(member)==0 and e.auraQueries==queries,client..": aura restrictions suppress absence claims")
    e.restricted=false;e.auraFailure=true;E.Update(member)
    check(shown(member)==0,client..": API failure is unknown rather than missing")
    e.auraFailure=false
    if client~="classic_era"then
        e.auraOverride=e.secret;E.Update(member)
        check(shown(member)==0,client..": secret aura table is never dereferenced")
        e.auraOverride=e.inaccessible;E.Update(member)
        check(shown(member)==0,client..": inaccessible aura table is never dereferenced")
        e.auraOverride={name=e.secret};E.Update(member)
        check(shown(member)==0,client..": secret aura name is never classified")
        e.auraOverride={name="Unrelated"};E.Update(member)
        check(shown(member)==0,client..": incomplete capped aura scan makes no absence claim")
        e.auraOverride=nil
    end
    e.existsResult=e.secret;queries=e.auraQueries;E.Update(member)
    check(shown(member)==0 and e.auraQueries==queries,client..": opaque unit existence causes no aura query")
    e.existsResult=nil
    db.showMissingClassBuffs=false;E.Update(member);queries=e.auraQueries;E.Update(member)
    check(shown(member)==0 and e.auraQueries==queries,client..": disabled marks stop aura queries")
    db.showClassBuffs=false;E.RefreshLayout()
    check(e.cellCount==0,client..": optional cells default off without rewriting profile defaults")
    check(not next(e.allFrames[#e.allFrames].events),client..": all adjuncts off unregister their events")
    db.showPets=true;E.RefreshLayout()
    local pets,target=E.GetExtraCells()
    check(#pets==45 and not target,client..": pet opt-in preallocates both secure roster modes OOC")
    check(pets[1].unit=="raidpet1"and pets[40].unit=="raidpet40"and pets[41].unit=="pet"and pets[45].unit=="partypet4",
        client..": fixed pet tokens cover all raid and party owners")
    check(pets[1].driver.condition=="[group:raid,@raidpet1,exists] show; hide"and pets[41].driver.condition=="[group:party,@pet,exists] show; hide",
        client..": secure conditions own mode and pet existence")
    check(pets[1].height==22 and pets[1].chrome.showPower==false,client..": pets use half-height cells without power")
    check(pets[1].template=="FluxRaidPetUnitTemplate,SecureHandlerStateTemplate",client..": pet flags belong to their template before OnLoad")
    check(e.FluxRaidState.containerFrame.width==592 and pets[1].points[1][3]=="TOPRIGHT",client..": extra cells anchor beside the existing unchanged grid")
    for _,pet in ipairs(pets)do check(pet.bindingRegistered and e.FluxRaidState.frameArray[pet],"pet template retains binding and event ownership")end
    db.showFriendlyTarget=true;E.RefreshLayout();pets,target=E.GetExtraCells()
    check(target.unit=="target"and target.driver.condition=="[group,@target,help,exists] show; hide",client..": target cell uses secure friendly/group visibility")
    check(target.height==43 and pets[1].points[1][5]==-51,client..": friendly target sits above optional pet cells")
    local count=e.cellCount;E.RefreshLayout();check(e.cellCount==count,client..": repeated layout reuses allocated cells")
    e.combat=true
    local snippet=target.attrs["_onstate-raidextra"]
    e.secure=true;assert(load(snippet,"@raid-extra-state","t",{self=target,newstate="hide"}))();e.secure=false
    check(not target.shown,client..": installed secure hide snippet runs during combat")
    e.secure=true;assert(load(snippet,"@raid-extra-state","t",{self=target,newstate="show"}))();e.secure=false
    check(target.shown,client..": installed secure show snippet runs during combat")
    db.showPets,db.showFriendlyTarget=false,false
    local mutations=e.mutations;E.RefreshLayout()
    check(e.mutations==mutations and pets[1].driver,client..": combat layout changes defer all protected writes")
    e.combat=false;E.OnEvent("PLAYER_REGEN_ENABLED")
    check(not pets[1].driver and not pets[1].shown and not pets[1].unit and not target.shown and not target.unit,
        client..": disabling adjuncts removes drivers, hides cells and unbinds units OOC")
    local paints=e.paintCount;E.OnEvent("UNIT_PET","player");E.OnEvent("PLAYER_TARGET_CHANGED")
    check(e.paintCount==paints,client..": disabled cells perform no event paint")
    db.showPets=true;e.support=false;E.RefreshLayout()
    check(E.extraStatus and not pets[1].shown,client..": unavailable secure support is explicit and does not show an insecure fallback")
    assert(load(read("AddonOptions/FluxOptionsRaidFrame.lua"),"@raid-extra-options","t",e))("_FluxUI",ns)
    local args=ns.FluxOptionsBuildPartyRaidTab().args
    db.showClassBuffs=nil
    db.showMissingClassBuffs=nil
    check(args.showClassBuffs.get()==true and args.showMissingClassBuffs.get()==false,
        "present buffs default on and missing-buff reminders default off per user selection")
    check(args.showEstimatedHoTs.get()==false,"HoT estimates are opt-in")
    check(args.showPets.get()==true and args.showFriendlyTarget.get()==false,"options use existing scoped settings")
    args.showPets.set(nil,false);args.showMissingClassBuffs.set(nil,true)
    check(db.showPets==false and db.showMissingClassBuffs==true and e.changes==2,"option edits use existing module refresh")
end

for _,client in ipairs({"live","forever","classic","classic_era","classic_anniversary"})do exercise(client)end
local noCombat=source:gsub('frame%._fluxRaidMini or Combat%(%) or not Enabled%(%)','frame._fluxRaidMini or not Enabled()')
check(not pcall(exercise,"live",noCombat),"negative control rejects aura scanning during combat")
local noDefer=source:gsub('if Combat%(%) then pendingLayout = true; SyncEvents%(%)%; return end','if false then return end')
check(not pcall(exercise,"live",noDefer),"negative control rejects insecure combat layout changes")
print("Raid healer adjuncts: "..checks.." checks; five client contracts; two rejected negative controls")

