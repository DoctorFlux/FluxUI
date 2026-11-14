-- Adversarial event order through actual pinned native header/state/wrap code.
-- The protected-operation guard is a desktop model, not native taint acceptance.
local function read(path)
    local f=assert(io.open(path,"rb"));local s=f:read("*a"):gsub("\r\n","\n");f:close();return s
end
local source=read("tests/raid_healer_secure.lua")
local exercise=assert(source:find("local function exercise(client)",1,true))
local prefix=source:sub(1,exercise-1)
prefix=prefix:gsub('local ns = { Flux = {} }','local ns = { Flux = {} }; e.ns=ns',1)
prefix=prefix:gsub('return e, secure, execute','e.resolveDriver=resolveDriver; return e, secure, execute',1)
if os.getenv("FLUX_COMBAT_ROSTER_SECURE_SOURCE")then
    prefix=prefix:gsub('root %.%. "RaidFrame/FluxRaidSecure.lua"',string.format("%q",os.getenv("FLUX_COMBAT_ROSTER_SECURE_SOURCE")),1)
end
local first=assert(source:find("    local function split(delimiter, text)",exercise,true))
local last=assert(source:find("    local function roster(mode, partyCount, rows, petbattle)",first,true))
local preparation=source:sub(first,last-1)
preparation=preparation:gsub('h.attrs%["child" %.%. i%], h.refs%["child" %.%. i%] = child, child',[[
child.scripts.OnAttributeChanged=function(self,name)
    if name=="unit"then e.callbackDepths[#e.callbackDepths+1]=e.depth end
end
h.attrs["child" .. i], h.refs["child" .. i] = child, child]],1)
local fixture=assert(load(prefix..[[
return function(client)
    local e,secure=fixture(client)
    local S=e.FluxRaidSecure
    e.callbackDepths={}
    local methods=getmetatable(e.CreateFrame("Frame","FixtureRoot")).__index
    function methods:GetParent()return self.parent end
    function methods:RegisterEvent(event)self.events=self.events or{};self.events[event]=true end
]]..preparation..[[
    -- Match real XML ancestry. A child Show must not mask a hidden parent.
    for _,h in ipairs(groups)do h.parent=container end
    mt.parent=container
    return e,secure,S,container,groups,mt
end
]],"@combat-roster-source-fixture","t",_G))()
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function near(a,b)return math.abs(a-b)<1e-7 end
for _,client in ipairs({"live","forever","classic","classic_era","classic_anniversary"})do
 for _,normal in ipairs({false,true})do
    local e,secure,S,container,groups,mt=fixture(client)
    local members,pets,targets={},{},{}
    if normal then
        e.ns.PartyFrames={ready=true}
        for i=1,8 do check(S.ConfigureHeader(groups[i],i,false),"normal mode prepares raid-only headers")end
        for i=1,4 do
            members[i]=e.CreateFrame("Button","Party"..i,container)
            pets[i]=e.CreateFrame("Button","PartyPet"..i,members[i])
            targets[i]=e.CreateFrame("Button","PartyTarget"..i,members[i])
            members[i].attrs.unit="party"..i;pets[i].attrs.unit="partypet"..i;targets[i].attrs.unit="party"..i.."target"
            members[i]:Hide();pets[i]:Hide();targets[i]:Hide()
        end
        check(S.ConfigurePartyFrames(members,pets,.5,1,true,true,targets,{showTargets=true,height=85}),"normal party existence/parent drivers prepared while solo")
    end
    local function exists(unit)
        if unit == "player" then return true end
        local i=tonumber(unit:match("(%d+)"))
        if unit:match("^raid%d+$")then return e.mode=="raid"and(e.raidRoster[i]~=nil or i==1)end
        if unit:match("^partypet")then return i<=e.partyCount and e.petPresent[i]end
        if unit:match("target$")then return i<=e.partyCount and e.targetPresent[i]end
        return i<=e.partyCount
    end
    e.SecureCmdOptionParse=assert(loadfile("tests/support/group_condition_parser.lua"))()({
        exists=exists,petbattle=function()return e.petbattle end,group=function()return e.mode end,
    })
    -- Also exercise the full native manager's event -> next-update path, not
    -- just its extracted resolver. GROUP_ROSTER_UPDATE resets its timer to zero.
    local cache=os.getenv("FLUX_RAID_UPSTREAM_CACHE")
    local nativeRoot=cache and cache.."/"..client or "../__AddonsForRef/wow-ui-source-"..client
    e.strmatch=string.match;e.wipe=e.table.wipe;e.UnitIsVisible=e.UnitExists
    assert(load(read(nativeRoot.."/Interface/AddOns/Blizzard_RestrictedAddOnEnvironment/SecureStateDriver.lua"),"@native-complete-state-driver","t",e))()
    for frame,driver in pairs(e.drivers)do e.RegisterStateDriver(frame,driver.state,driver.condition)end
    local manager=e.SecureStateDriverManager
    check(manager.events.GROUP_ROSTER_UPDATE and manager.events.UNIT_PET,"native manager subscribes to roster/pet rescans")
    local states={
        {mode="solo"}, {mode="party",n=1}, {mode="party",n=4},
        {mode="party",n=2}, {mode="solo"}, {mode="raid",rows={{group=8,mt=true},{group=2},{group=8}}},
        {mode="raid",rows={{group=3},{group=1,mt=true},{group=3,mt=true},{group=7}}},
        {mode="party",n=3}, {mode="raid",rows={}}, {mode="solo"},
    }
    local full={};for i=1,40 do full[i]={group=math.ceil(i/5),mt=i%3==0,name="Member"..i}end
    states[#states+1]={mode="raid",rows=full}
    local moved={};for i=1,40 do moved[i]={group=9-math.ceil(i/5),mt=i%2==0,name="Moved"..i}end
    states[#states+1]={mode="raid",rows=moved}
    states[#states+1]={mode="party",n=4,petbattle=true}
    states[#states+1]={mode="party",n=4}
    states[#states+1]={mode="solo"}
    local capacity=e.created
    local function snapshot(label)
        local raid=e.mode=="raid"and not e.petbattle
        local compact=e.mode=="party"and not normal and not e.petbattle
        if raid or compact or normal and e.mode=="party"and not e.petbattle then check(container:IsVisible(),label..": hidden parent is revealed")end
        local occupied={};local mtUnits={}
        for group,h in ipairs(groups)do
            local expected={}
            if raid then
                for i,row in ipairs(e.raidRoster)do if row.group==group then expected[#expected+1]="raid"..i end end
            elseif compact and group==1 then
                expected[1]="player";for i=1,e.partyCount do expected[#expected+1]="party"..i end
            end
            check(h:IsShown()==(raid or compact and group==1),label..": native header visibility")
            if #expected>0 then occupied[#occupied+1]=group end
            for i=1,5 do
                local child=h.attrs["child"..i]
                if h:IsShown()then
                    check(child.attrs.unit==expected[i],label..": native slot follows latest roster/group index")
                    check(child:IsVisible()==(expected[i]~=nil),label..": populated/retired child visibility")
                else check(not child:IsVisible(),label..": no clickable child under a hidden group")end
            end
            check(h.alpha==(#expected>0 and 1 or 0),label..": empty groups do not retain visible chrome")
        end
        local mtCount=0
        if raid then for _,row in ipairs(e.raidRoster)do if row.mt then mtCount=mtCount+1 end end end
        local slots=math.max(9,#occupied+math.ceil(mtCount/4))
        for rank,group in ipairs(occupied)do check(near(groups[group].point[4],(slots-rank)*74),label..": reverse occupied-group placement")end
        check(mt:IsShown()==raid,label..": native MT header follows group mode")
        if raid then
            for i,row in ipairs(e.raidRoster)do if row.mt then mtUnits[#mtUnits+1]="raid"..i end end
            for i=1,40 do check(mt.attrs["child"..i].attrs.unit==mtUnits[i],label..": MT role membership reassigns/clears")end
        end
        if normal then
            for i=1,4 do
                local present=e.mode=="party"and not e.petbattle and i<=e.partyCount
                check(members[i]:IsVisible()==present,label..": normal member immediate existence")
                check(pets[i]:IsVisible()==(present and e.petPresent[i]or false),label..": pet join/leave existence")
                check(targets[i]:IsVisible()==(present and e.targetPresent[i]or false),label..": party target join/leave existence")
            end
        end
        check(e.created==capacity,label..": no combat allocation")
    end
    e.combat=true
    for order=1,4 do
        for repetition=1,3 do
            for step,state in ipairs(states)do
                e.mode,e.partyCount,e.raidRoster,e.petbattle=state.mode,state.n or 0,state.rows or{},state.petbattle
                e.petPresent={repetition~=2,true,false,true};e.targetPresent={true,repetition~=3,true,false}
                if step==2 or step==6 then secure(container.Hide,container)end
                local drivers={};for frame,driver in pairs(e.drivers)do drivers[#drivers+1]={frame,driver}end
                local function key(frame)return frame:GetName()or(frame.refs.header and frame.refs.header:GetName())or""end
                table.sort(drivers,function(a,b)return key(a[1])<key(b[1])end)
                if order==3 then for i=1,math.floor(#drivers/2)do drivers[i],drivers[#drivers-i+1]=drivers[#drivers-i+1],drivers[i]end end
                local function drive(index)
                    local item=drivers[index]
                    if item then e.resolveDriver(item[1],"state-"..item[2].state,item[2].condition)end
                end
                secure(function()
                    if order==2 or order==4 then
                        for i=8,1,-1 do e.SecureGroupHeader_OnEvent(groups[i],"GROUP_ROSTER_UPDATE")end
                        e.SecureGroupHeader_OnEvent(mt,"GROUP_ROSTER_UPDATE")
                    end
                    for i=1,math.max(#drivers,9)do
                        if order~=4 then drive(i)end
                        if order==3 then
                            local h=groups[10-i]or(i==1 and mt)
                            if h then e.SecureGroupHeader_OnEvent(h,"GROUP_ROSTER_UPDATE")end
                        end
                    end
                    if order==1 then
                        for _,h in ipairs(groups)do e.SecureGroupHeader_OnEvent(h,"GROUP_ROSTER_UPDATE")end
                        e.SecureGroupHeader_OnEvent(mt,"GROUP_ROSTER_UPDATE")
                    elseif order==4 then
                        manager.scripts.OnEvent(manager,"GROUP_ROSTER_UPDATE")
                        manager.scripts.OnUpdate(manager,1/60)
                    end
                end)
                snapshot(client..":"..(normal and"normal"or"compact")..":"..order..":"..step)
            end
        end
    end
    check(#e.callbackDepths>0,"native unit reassignment and presentation callbacks exercised")
    for _,depth in ipairs(e.callbackDepths)do check(depth==0,"ordinary presentation callback has no protected authority")end
    print("COMBAT_ROSTER|"..client.."|"..(normal and"normal"or"compact").."|transitions=180|newFrames="..(e.created-capacity))
 end
end
print("Combat roster transitions: "..checks.." checks PASS; native secure VM/taint/timing acceptance pending")
