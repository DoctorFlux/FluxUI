-- Execute the pinned client's real AuraUtil visibility/classification/comparators.
-- Native group assignment is modeled from the real public candidate predicate;
-- engine filter membership, secret execution, rendering and taint remain pending.
-- FLUX_RAID_AURA_SOURCE injects an external baseline into the same fixtures.
-- FLUX_RAID_AURA_REPORT_ONLY=1 reports all functional failures without aborting.
local function read(path)local f=assert(io.open(path,"rb"));local s=f:read("*a"):gsub("\r\n","\n");f:close();return s end
local fixtureSource=read("tests/raid_healer_auras.lua")
local prefix=assert(fixtureSource:match("^(.-)\nfor _,client in ipairs"))
local Fixture=assert(load(prefix.."\nreturn Fixture","@aura-fixture","t",_G))()
local cache=os.getenv("FLUX_RAID_UPSTREAM_CACHE")
local passed,failed=0,0
local function test(label,fn)
    local ok,error=pcall(fn)
    if ok then passed=passed+1 else failed=failed+1;print("FAIL "..label..": "..tostring(error))end
end
local function aura(id,helpful,extra)
    local a={name="Aura"..id,spellId=id,auraInstanceID=id,icon=1000+id,sourceUnit="player",canApplyAura=true,
        isHelpful=helpful,isHarmful=not helpful,isRaid=false,isBossAura=false,isPriorityAura=false,
        isTankRoleAura=false,isHealerRoleAura=false,isDPSRoleAura=false,isNameplateOnly=false,duration=30,expirationTime=100,applications=1}
    for key,value in pairs(extra or{})do a[key]=value end
    return a
end
local function icons(list)
    local ids={};for _,button in ipairs(list)do if button.shown then ids[#ids+1]=button.Icon.texture-1000 end end
    return table.concat(ids,",")
end
local function setup(client,native)
    local e,module,frame,frames,boxes,data=Fixture(native,nil,nil,client)
    e.FluxOptions={GetRaidFrameDB=function()return{showClassBuffs=false}end}
    return e,module,frame,data
end
local function playerFilters(data)
    for _,kind in ipairs({"HELPFUL","HARMFUL"})do
        if not data[kind.."|PLAYER"]then
            local list={};data[kind.."|PLAYER"]=list
            for _,a in ipairs(data[kind]or{})do
                if a.sourceUnit=="player"or a.sourceUnit=="pet"or a.sourceUnit=="vehicle"then list[#list+1]=a end
            end
        end
    end
end
local function nativePredicate(e,client)
    local base=cache and cache.."/"..client.."/" or "../__AddonsForRef/wow-ui-source-"..client.."/"
    local text=read(base.."Interface/AddOns/Blizzard_AuraContainer/Blizzard_AuraContainerUtil.lua")
    e.AuraContainerUtil={}
    e.C_Secrets={GetSpellAuraSecrecy=function()return 1 end};e.Enum.SecrecyLevel={NeverSecret=0}
    e.UnitIsPlayerControlledOrGroupMember=function()return true end;e.UnitCanAssist=function()return true end
    for _,name in ipairs({"CanApplyIdentityCandidateFilters","DoesAuraPassCandidateFilters"})do
        local fn=assert(text:match("function AuraContainerUtil%."..name.."%b().-\nend"))
        assert(load(fn,"@native-public-candidate-"..client,"t",e))()
    end
end
local function nativeIcons(e,frame,data,key)
    local box=frame._fluxAuraContainers[key]
    if box.enabled~=true or not box.shown or box.unit=="none"then return""end
    local groups={};for _,group in pairs(box.groups)do if group.enabled then groups[#groups+1]=group end end
    table.sort(groups,function(a,b)return a.options.layout.layoutIndex<b.options.layout.layoutIndex end)
    local result={}
    for _,group in ipairs(groups)do
        local members={}
        for _,original in ipairs(data[group.filter]or{})do
            local copy={};for k,v in pairs(original)do copy[k]=v end
            copy.processedAuraType=e.AuraUtil.ProcessAura(copy,false,false,false,false)
            if e.AuraContainerUtil.DoesAuraPassCandidateFilters(frame.unit,copy,group.options.candidateFilters)then members[#members+1]=copy end
        end
        local comparator=group.options.sortMethod==e.AuraContainerSortMethod.UnitFrameDebuff
            and e.AuraUtil.UnitFrameDebuffComparator or e.AuraUtil.DefaultAuraCompare
        table.sort(members,comparator)
        for i=1,math.min(#members,group.options.maxFrameCount)do
            result[#result+1]=members[i].spellId;if #result==6 then return table.concat(result,",")end
        end
    end
    return table.concat(result,",")
end
local cases={
    {"own shield",function(e,d)d.HELPFUL={aura(17,true)}end,"17",""},
    {"own long buff",function(e,d)d.HELPFUL={aura(18,true,{duration=600})}end,"18",""},
    {"own permanent buff",function(e,d)d.HELPFUL={aura(19,true,{duration=0})}end,"19",""},
    {"foreign spec-visible buff",function(e,d)e.visibility[20]={true,false,true};d.HELPFUL={aura(20,true,{sourceUnit="party2"})}end,"20",""},
    {"self-only buff excluded",function(e,d)e.selfBuffs[21]=true;d.HELPFUL={aura(21,true)};d["HELPFUL|PLAYER"]=d.HELPFUL end,"",""},
    {"uncastable own buff excluded",function(e,d)d.HELPFUL={aura(22,true,{canApplyAura=false})};d["HELPFUL|PLAYER"]=d.HELPFUL end,"",""},
    {"custom-hidden own buff",function(e,d)e.visibility[23]={true,false,false};d.HELPFUL={aura(23,true)};d["HELPFUL|PLAYER"]=d.HELPFUL end,"",""},
    {"custom mine-visible pet buff",function(e,d)e.visibility[24]={true,true,false};d.HELPFUL={aura(24,true,{sourceUnit="pet"})}end,"24",""},
    {"long other-caster debuff",function(e,d)d.HARMFUL={aura(25,false,{duration=900,sourceUnit="party2"})}end,"","25"},
    {"permanent ordinary debuff",function(e,d)d.HARMFUL={aura(26,false,{duration=0,sourceUnit="party2"})}end,"","26"},
    {"custom-hidden short debuff",function(e,d)e.visibility[27]={true,false,false};d.HARMFUL={aura(27,false,{sourceUnit="party2"})}end,"",""},
    {"boss helpful aura on debuff side",function(e,d)d.HELPFUL={aura(28,true,{isBossAura=true,sourceUnit="boss1"})}end,"","28"},
    {"role helpful aura on debuff side",function(e,d)d.HELPFUL={aura(29,true,{isHealerRoleAura=true,sourceUnit="boss1"})}end,"","29"},
    {"native gameplay priority",function(e,d)
        e.priority[33]=true
        d.HARMFUL={aura(31,false),aura(32,false,{isRaid=true,dispelName="Magic"}),aura(33,false,{sourceUnit="party2"}),aura(35,false,{isBossAura=true,sourceUnit="boss1"})}
        d["HARMFUL|PLAYER"]={d.HARMFUL[1]};d["HARMFUL|RAID"]={d.HARMFUL[2]}
        d.HELPFUL={aura(34,true,{isBossAura=true,sourceUnit="boss1"})}
    end,"","35,34,33,32,31"},
    {"default buff caster-priority-applicability",function(e,d)
        e.visibility[40]={true,false,true};e.visibility[41]={true,false,true};e.priority[41]=true
        d.HELPFUL={aura(40,true,{sourceUnit="party2"}),aura(41,true,{sourceUnit="party2"}),aura(42,true)}
    end,"42,41,40",""},
}
local clients={"live","forever","classic","classic_era","classic_anniversary"}
for _,client in ipairs(clients)do
    for _,case in ipairs(cases)do
        test(client.." readable "..case[1],function()
            local e,module,frame,data=setup(client,false);case[2](e,data);playerFilters(data);module.Setup(frame);module.Update(frame)
            assert(icons(frame._fluxAuraCorners.buffs)==case[3],"buff eligibility/order diverges from pinned native policy")
            assert(icons(frame._fluxAuraCorners.debuffs)==case[4],"debuff eligibility/order diverges from pinned native policy")
        end)
        if client=="live"or client=="forever"then test(client.." native "..case[1],function()
            local e,module,frame,data=setup(client,true);nativePredicate(e,client);case[2](e,data);playerFilters(data);module.Setup(frame);module.Update(frame)
            assert(nativeIcons(e,frame,data,"buffs")==case[3],"public native buff groups diverge from native policy")
            assert(nativeIcons(e,frame,data,"dispel")==case[4],"public native debuff groups diverge from native priority")
        end)end
    end
    test(client.." strict raw raid membership bypasses custom visibility safely",function()
        local e,module,frame,data=setup(client,false);e.visibility[50]={true,false,false}
        data["HARMFUL|RAID"]={aura(50,false,{isRaid=false,canActivePlayerDispel=true,dispelName="Magic"}),aura(51,false,{isRaid=true,dispelName="Magic"})}
        frame.optionTable.displayOnlyDispellableDebuffs=true;module.Setup(frame);module.Update(frame)
        assert(icons(frame._fluxAuraCorners.debuffs)=="50,51","strict RAID membership was lost to custom visibility")
        for _,field in ipairs({"spellId","sourceUnit","auraInstanceID","isPriorityAura","canApplyAura","debuffType"})do
            data["HARMFUL|RAID"][1][field]={secret=true};module.Update(frame)
            assert(icons(frame._fluxAuraCorners.debuffs)=="51","opaque comparator field reached readable sorting")
            data["HARMFUL|RAID"][1]=aura(50,false,{isRaid=true,dispelName="Magic"})
        end
    end)
    test(client.." readable party-hidden aura excluded",function()
        local e,module,frame,data=setup(client,false);data.HARMFUL={aura(60,false,{hideOnPartyFrames=true})}
        module.Setup(frame);module.Update(frame);assert(icons(frame._fluxAuraCorners.debuffs)=="")
    end)
    test(client.." readable UnitAura-only records preserve known query context",function()
        local e,module,frame,data=setup(client,false)
        data.HELPFUL={aura(18,true,{duration=600}),aura(19,true,{duration=0}),aura(17,true),aura(34,true,{isBossAura=true,sourceUnit="boss1"})}
        data.HARMFUL={aura(31,false),aura(32,false,{dispelName="Magic"})};data["HARMFUL|RAID"]={data.HARMFUL[2]}
        e.C_UnitAuras.GetAuraDataByIndex=nil
        e.UnitAura=function(_,index,filter)
            local a=data[filter]and data[filter][index];if not a then return end
            return a.name,a.icon,a.applications,a.dispelName,a.duration,a.expirationTime,a.sourceUnit,false,false,a.spellId,a.canApplyAura,a.isBossAura
        end
        module.Setup(frame);module.Update(frame)
        assert(icons(frame._fluxAuraCorners.buffs)=="18,19,17","legacy buffs lost without modern instance IDs")
        assert(icons(frame._fluxAuraCorners.debuffs)=="34,32,31","legacy query membership/priority/dedup lost")
        assert(data.HELPFUL[1].auraInstanceID==18,"legacy normalization mutated the service's record")
    end)
end
for _,client in ipairs({"live","forever"})do
    test(client.." explicit OOC class buffs survive native hidden group-buff settings",function()
        for _,native in ipairs({false,true})do
            local e,module,frame,data=setup(client,native);if native then nativePredicate(e,client)end
            e.FluxOptions={GetRaidFrameDB=function()return{showClassBuffs=true}end}
            e.C_UnitAuras.GetHiddenGroupBuffs=function()return{1243}end
            data.HELPFUL={aura(1243,true,{sourceUnit="party2",canApplyAura=false})}
            module.Setup(frame);module.Update(frame)
            local function shown()return native and nativeIcons(e,frame,data,"buffs")or icons(frame._fluxAuraCorners.buffs)end
            assert(shown()=="1243","native hidden group IDs suppressed the explicit class-buff supplement")
            e.combat=true;module.Update(frame);assert(shown()=="","class supplement failed to stop in combat")
            e.combat=false;module.Update(frame);assert(shown()=="1243","class supplement failed to resume OOC")
        end
    end)
    test(client.." native intrinsic owners begin enabled",function()
        local base=cache and cache.."/"..client.."/"or"../__AddonsForRef/wow-ui-source-"..client.."/"
        local xml=read(base.."Interface/AddOns/Blizzard_AuraContainer/Blizzard_AuraContainer.xml")
        assert(xml:find('key="enabled" value="true" type="boolean"',1,true),"native intrinsic enable default changed")
        local e,module,frame,data=setup(client,true);nativePredicate(e,client)
        data.HELPFUL={aura(70,true)};module.Setup(frame);module.Update(frame)
        assert(nativeIcons(e,frame,data,"buffs")=="70","valid enabled owner is silent")
        frame._fluxAuraContainers.buffs:SetEnabled(false)
        assert(nativeIcons(e,frame,data,"buffs")=="","negative control ignores disabled native owner")
    end)
    test(client.." hidden group-buff changes update native and readable owners",function()
        for _,native in ipairs({false,true})do
            local e,module,frame,data=setup(client,native);if native then nativePredicate(e,client)end
            local hidden={};e.C_UnitAuras.GetHiddenGroupBuffs=function()return hidden end
            data.HELPFUL={aura(70,true)};playerFilters(data);module.Setup(frame);module.Update(frame)
            local function shown()return native and nativeIcons(e,frame,data,"buffs")or icons(frame._fluxAuraCorners.buffs)end
            assert(shown()=="70");e.combat=true;hidden={70};module.OnHiddenGroupBuffsChanged();module.Update(frame);assert(shown()=="")
            hidden={};module.OnHiddenGroupBuffsChanged();module.Update(frame);assert(shown()=="70")
        end
    end)
end
print("Raid native aura policy: "..passed.." passed, "..failed.." failed; five pinned client policies, public native predicates; native VM/rendering pending")
if os.getenv("FLUX_RAID_AURA_REPORT_ONLY")~="1"then assert(failed==0,"native aura policy regressions")end
