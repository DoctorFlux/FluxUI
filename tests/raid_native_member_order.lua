-- Compare member order against the actual native discrete-group and party code.
-- FLUX_RAID_UPSTREAM_CACHE selects this task's immutable five-branch cache.
local root=(arg[0]:match("^(.*)[/\\]")or".").."/../"
local cache=os.getenv("FLUX_RAID_UPSTREAM_CACHE")
local checks=0
local function check(value,label)checks=checks+1;assert(value,label)end
local function read(path)local f=assert(io.open(path,"rb"),path);local s=f:read("*a"):gsub("\r\n","\n");f:close();return s end
local function source(client,path)
    return read((cache and cache.."/"..client.."/"or root.."../__AddonsForRef/wow-ui-source-"..client.."/").."Interface/AddOns/"..path)
end
local function layoutContract(text)
    assert(text:find('header:SetAttribute%("sortMethod",%s*"INDEX"%)'),"Flux members must use native index order")
    assert(text:find('header:SetAttribute%("sortDir",%s*"ASC"%)'),"Flux members must use ascending native slots")
end
local layout=read(root.."RaidFrame/FluxRaidLayout.lua")
check(pcall(layoutContract,layout),"production header selects native INDEX/ASC ordering")
local changed,count=layout:gsub('header:SetAttribute%("sortMethod",%s*"INDEX"%)','header:SetAttribute("sortMethod", "NAME")')
check(count>0 and not pcall(layoutContract,changed),"negative control rejects alphabetical production member ordering")

for _,client in ipairs({"live","forever","classic","classic_era","classic_anniversary"})do
    local e=setmetatable({},{__index=_G});e._G=e
    local rows={
        {name="Zulu",group=1,role="DAMAGER"},{name="Alpha",group=1,role="HEALER"},
        {name="Tango",group=2,role="TANK"},{name="Bravo",group=1,role="DAMAGER"},
        {name="Charlie",group=2,role="DAMAGER"},
    }
    local raid=true
    e.MEMBERS_PER_RAID_GROUP=5
    e.CompactRaidGroupTypeEnum={Raid=1,Party=2}
    e.GetNumGroupMembers=function()return raid and #rows or 5 end
    e.IsInRaid=function()return raid end
    e.GetRaidRosterInfo=function(i)local r=rows[i];if r then return r.name,nil,r.group,nil,nil,nil,nil,nil,nil,nil end end
    e.ShouldShowRaidFrames=function()return true end
    e.UnitExists=function()return true end
    e.EditModeManagerFrame={AreRaidFramesForcedShown=function()return false end,ArePartyFramesForcedShown=function()return false end}
    e.UnitName=function(unit)
        local i=tonumber(unit:match("^raid(%d+)$"))
        if i then return rows[i]and rows[i].name end
        return unit=="player"and"ZuluPlayer"or(unit=="party1"and"AlphaParty"or unit)
    end
    e.UnitInRaid=function(unit)return tonumber(unit:match("^raid(%d+)$"))end
    e.UnitGroupRolesAssigned=function(unit)local i=e.UnitInRaid(unit);return i and rows[i].role or"DAMAGER"end
    e.CompactUnitFrame_SetUnit=function(frame,unit)frame.unit=unit end
    e.CompactUnitFrame_SetUpFrame=function()end
    e.CompactUnitFrame_SetUpdateAllEvent=function()end
    e.CompactRaidFrameContainer={displayPets=false}
    e.PartyFrame={UpdatePaddingAndLayout=function()end}
    local container=source(client,"Blizzard_CompactRaidFrames/Blizzard_CompactRaidFrameContainer.lua")
    local start=assert(container:find("function CRFSort_Group",1,true))
    assert(load(container:sub(start),"@native-member-comparators-"..client,"t",e))()
    local groupSource=source(client,"Blizzard_UnitFrame/Shared/CompactRaidGroup.lua")
    local update=assert(groupSource:match("function CompactRaidGroup_UpdateUnits%(.-\nend"))
    assert(load(update,"@native-discrete-member-order-"..client,"t",e))()
    local function nativeGroup(group)
        local name="TestNativeGroup"..group
        local frame={groupType=1,GetID=function()return group end,GetName=function()return name end,updateLayoutFunc=function()end}
        for i=1,5 do e[name.."Member"..i]={}end
        e.CompactRaidGroup_UpdateUnits(frame)
        local units={};for i=1,5 do units[i]=e[name.."Member"..i].unit end
        return units
    end
    local first,second=nativeGroup(1),nativeGroup(2)
    check(first[1]=="raid1"and first[2]=="raid2"and first[3]=="raid4"and first[4]==nil,
        client..": native discrete group follows raid slot order rather than alphabetical names")
    check(second[1]=="raid3"and second[2]=="raid5",client..": subgroup filtering retains original raid indices")
    local tokens={"raid4","raid2","raid5","raid3","raid1"}
    table.sort(tokens,e.CRFSort_Group)
    check(table.concat(tokens,",")=="raid1,raid2,raid4,raid3,raid5",client..": native group comparator orders subgroup then numeric raid slot")
    local alphabetical={"raid1","raid2","raid4"};table.sort(alphabetical,e.CRFSort_Alphabetical)
    check(alphabetical[1]=="raid2"and alphabetical[1]~=first[1],client..": nonalphabetical names expose the former NAME regression")
    local roleSorted={"raid1","raid2","raid3"};table.sort(roleSorted,e.CRFSort_Role)
    check(roleSorted[1]=="raid3"and first[1]=="raid1",client..": optional flat role ordering does not alter discrete group rows")
    raid=false
    local party=source(client,"Blizzard_UnitFrame/Shared/CompactPartyFrame.lua")
    check(party:find("frame.flowSortFunc = CRFSort_Group",1,true)~=nil,client..": native party defaults to group ordering")
    e.CompactPartyFrameMixin={}
    local refresh=assert(party:match("function CompactPartyFrameMixin:RefreshMembers%(.-\nend"))
    assert(load(refresh,"@native-party-member-order-"..client,"t",e))()
    local frame={memberUnitFrames={{},{},{},{},{}},petUnitFrames={},flowSortFunc=e.CRFSort_Group,updateLayoutFunc=function()end}
    e.CompactPartyFrameMixin.RefreshMembers(frame)
    local expected={"player","party1","party2","party3","party4"}
    for i,unit in ipairs(expected)do check(frame.memberUnitFrames[i].unit==unit,client..": native party keeps player first then party indices")end
end

do
    local e=setmetatable({},{__index=_G});e._G=e
    assert(loadfile(root.."RaidFrame/FluxRaidCompat.lua","t",e))("_FluxUI",{})
    local groups=e.FluxRaidCompat.BuildVisibleGroupsReverse(function(index)return index==1 or index==4 or index==8 end)
    local geometry=e.FluxRaidCompat.ComputeReverseColumnLayout(groups,true,2,72)
    check(groups[1]==8 and groups[3]==1 and geometry.groupX[1]>geometry.groupX[4]
        and geometry.groupX[4]>geometry.groupX[8] and geometry.xMT<geometry.groupX[8],
        "native within-column order preserves Flux reverse group columns and MTMA placement")
end
print("Raid native member order: "..checks.." checks; five native discrete/party ordering implementations, alphabetical negative control; desktop source execution only")
