-- Actual collection/config owners, caller functions and timer handler.
local root=arg[1]or".";if not root:match("[/\\]$")then root=root.."/"end
local selected=arg[2]
local checks=0
local function check(v,msg)checks=checks+1;assert(v,msg)end
local function read(p)local f=assert(io.open(root..p,"rb"));local s=f:read("*a");f:close();return(s:gsub("\r\n","\n"))end
local function part(s,a,b)local i=assert(s:find(a,1,true),a);return s:sub(i,assert(s:find(b,i+#a,true),b)-1)end
local collection=read("ExtraButtonSystem/NonCombatGrid/Buttons/MountCollection.lua")
local config=read("ExtraButtonSystem/NonCombatGrid/FluxSmartMountConfig.lua")
local mount=read("ExtraButtonSystem/NonCombatGrid/Buttons/Mount.lua")
local function env()
    local e=setmetatable({},{__index=_G});e._G=e
    e.CreateFrame=function()return{RegisterEvent=function()end,SetScript=function()end}end
    e.Enum={PlayerInteractionType={}}
    e.C_Timer={After=function()end};return e
end
local macroBody=part(mount,"function Module.HasBrutosaur()","-- Get macro for current mode")
local hasVendor=part(mount,"function Module.HasAnyVendorMount()","-- Get the best vendor mount")
local bestVendor=part(mount,"function Module.GetBestVendorMount()","-- MOUNT CONFIGURATION")
local middle=part(mount,"function Module.SetupMiddleClick(btn)","-- Set up PreClick hook")
local update=part(mount,"function Module.Update()","-- EVENT HANDLING")
if selected~="timers" then
for _,locale in ipairs(selected=="locale" and {"deDE"}or{"enUS","deDE","frFR","zhTW"})do
    for _,vendor in ipairs({465235,122708,61425,61447,0})do
        local e=env();local ids={};for i=1,1000 do ids[i]=i end
        local queries=0;local spell=vendor;local collected=true;local ready=true
        local name=locale.." Vendor";if locale=="enUS"then name=vendor==465235 and"Trader's Gilded Brutosaur"or vendor==122708 and"Grand Expedition Yak"or"Traveler's Tundra Mammoth"end
        e.FLUX_API={majorVersion=12,hasC_MountJournal=true}
        e.C_MountJournal={GetMountIDs=function()return ids end,GetMountInfoByID=function(id)
            queries=queries+1
            if id==1000 then return ready and name or nil,spell,"vendor-icon",false,true,0,false,false,0,false,collected end
            return "Ordinary"..id,100000+id,"ordinary-icon",false,true,0,false,false,0,false,true
        end}
        assert(load(collection,"@MountCollection.lua","t",e))()
        -- Config is loaded in full, with initialization events held quiet.
        assert(load(config,"@FluxSmartMountConfig.lua","t",e))()
        local coll,conf=e.FluxNCMountCollection,e.FluxSmartMountConfig
        local detected=conf.GetVendorMount()
        print(("METRIC vendor locale=%s spell=%d detected=%s firstQueries=%d"):format(locale,vendor,tostring(detected~=nil),queries))
        check(detected==(vendor~=0 and name or nil),"stable spell identity detects native localized vendor name")
        check(queries==1000,"first vendor lookup enumerates collection once")
        for i=1,1000 do check(conf.HasAnyVendorMount()==(vendor~=0),"cached vendor present/absent truth")end
        print(("METRIC vendor_cached locale=%s spell=%d lookups=1000 totalQueries=%d"):format(locale,vendor,queries))
        check(queries==1000,"positive and negative vendor lookups add zero journal queries")
        local noop=function()end;local writes=0
        e.InCombatLockdown=function()return false end;e.HasMountUI=function()return true end
        e.GetCurrentHeldModKey=function()return"nomod"end;e.ClearMountButtonCheckedState=noop
        e.GetOpenMountUIMacro=function()return"OPEN_COLLECTIONS"end
        e.Module={_button={Widget={Show=noop,SetAttribute=function()writes=writes+1 end}},_lastJournalMacro="/cast Configured",
            HasRidingSkill=function()return true end,UpdateButtonScope=noop,CanDisplayMountButton=function()return true end,
            GetCurrentMacro=function()return"/cast Configured"end,UpdateTexture=noop,SetupRightClick=noop,UpdateHotkeyText=noop,
            UpdateJournalMountIcon=noop,RefreshTooltip=noop,UpdateMountKeybinding=noop}
        assert(load(hasVendor..bestVendor..middle..update..macroBody,"@Mount-actual-vendor-callers","t",e))()
        for i=1,100 do e.Module.Update()end
        check(queries==1000 and writes==200,"100 actual mount updates reuse cache and preserve middle-click writes")
        local entry=e.Module.GetBestVendorMount()
        check((entry and entry.name)==detected,"config, button, vendor icon identity agree")
        local macro=e.Module.BuildVendorMountMacro()
        if vendor==465235 or vendor==122708 then check(macro:find(name,1,true)~=nil,"vendor macro uses localized cast name")
        else check(macro=="OPEN_COLLECTIONS","Mammoth-only vendor-mode behavior remains unchanged")end
        collected=false;coll.InvalidateCollectedMountMap()
        check(conf.GetVendorMount()==nil,"collection change invalidates positive ownership")
        spell=122708;collected=true;ready=false;coll.InvalidateCollectedMountMap()
        check(conf.GetVendorMount()==nil,"incomplete metadata is not invented")
        ready=true;coll.InvalidateCollectedMountMap()
        check(conf.GetVendorMount()==name,"readiness invalidation recovers native late metadata")
    end
end
do
    local e=env();local entries={{"Alliance Mammoth",61425,false},{"Horde Mammoth",61447,true},{"Localized Bruto",465235,false},{"Localized Yak",122708,true}}
    local ids={1,2};e.FLUX_API={majorVersion=12,hasC_MountJournal=true}
    e.C_MountJournal={GetMountIDs=function()return ids end,GetMountInfoByID=function(id)
        local v=entries[id];return v[1],v[2],"icon",false,v[3],0,false,false,0,false,true
    end}
    assert(load(collection,"@MountCollection-factions","t",e))()
    local c=e.FluxNCMountCollection
    check(c.GetBestVendorMount().spellID==61447,"prefer usable faction variant within Mammoth priority")
    ids={3,4,1,2};c.InvalidateCollectedMountMap()
    check(c.GetBestVendorMount().spellID==465235,"vendor priority remains above temporary usability")
    e.Module={};e.GetOpenMountUIMacro=function()return"OPEN"end
    assert(load(macroBody,"@Mount-localized-vendor-macro","t",e))()
    local macro=e.Module.BuildVendorMountMacro()
    check(macro:find("[mod] Localized Bruto",1,true)~=nil and macro:find("[nomod] Localized Yak",1,true)~=nil,"both-vendor macro preserves modifier priority with localized names")
end
do
    local e=env();local list={{"Localized Bruto",465235},{"Localized Yak",122708},{"Localized Mammoth",61447}}
    e.FLUX_API={majorVersion=3,hasC_MountJournal=false}
    e.GetNumCompanions=function()return#list end
    e.GetCompanionInfo=function(_,i)return i,list[i][1],list[i][2],"icon"end
    assert(load(collection,"@MountCollection-companions","t",e))()
    local c=e.FluxNCMountCollection
    check(c.GetBestVendorMount().name==list[1][1],"companion path preserves Bruto over Yak over Mammoth priority")
    check(c.GetYak().name==list[2][1],"companion localized Yak identity")
    list[1]=list[3];list[3]=nil;c.InvalidateCollectedMountMap()
    check(c.GetBestVendorMount().spellID==122708,"collection invalidation changes vendor priority")
    e.GetNumCompanions=function()return 0 end;c.InvalidateCollectedMountMap()
    check(not c.HasAnyVendorMount(),"companion removal invalidates negative ownership")
end
end
-- Run the actual timer shim, client gate and skill/spell dispatcher. After is void.
local alias=part(mount,"local Timer = C_Timer or {}","-- Held modifier helpers")
local gate=part(mount,"local function HasMountJournalAPI()","Module.HasMountUI = HasMountUI")
local handler=part(mount,"local function OnSpellBookChanged()","local eventFrame = CreateFrame")
for _,model in ipairs({{"era",1,true,false},{"anniversary",2,false,true},{"live",12,false,false},{"forever",1,false,false},{"progression",5,false,false}})do
    for _,combat in ipairs({false,true})do
        local e=env();local queue,updates,invalidations={},0,0
        e.C_Timer.After=function(delay,fn)queue[#queue+1]={delay=delay,fn=fn}end
        e.InCombatLockdown=function()return combat end
        e.FLUX_API={majorVersion=model[2],isClassicEra=model[3],isTBC=model[4],hasC_MountJournal=true}
        e.C_MountJournal={GetMountIDs=function()return{}end}
        e.Module={_registered=true,InvalidateRidingSkillCache=function()end,
            InvalidateCollectedMountCache=function()invalidations=invalidations+1 end,
            Update=function()check(not combat,"no delayed mount paint in combat");updates=updates+1 end}
        e.InvalidateAllMountItemCaches=function()end
        local changed=assert(load(alias..gate..handler.."\nreturn OnSpellBookChanged","@Mount-skill-timer","t",e))()
        for i=1,1000 do changed()end
        local bag=model[2]<=2;local short,long=0,0
        for _,t in ipairs(queue)do if t.delay==.3 then short=short+1 elseif t.delay==.5 then long=long+1 end end
        print(("METRIC mount_timer client=%s combat=%s requests=1000 bagCallbacks=%d halfSecondCallbacks=%d"):format(model[1],tostring(combat),short,long))
        check(short==(bag and 1 or 0) and long==(combat and 0 or 1),"burst owns one callback per existing mount deadline")
        check((e.Module._itemInfoTimer~=nil)==bag,"pending bag latch independent of void After return")
        local pending=queue;queue={};for _,t in ipairs(pending)do t.fn()end
        check(updates==(combat and 0 or #pending),"eligible callbacks retain update completion")
        check(not e.Module._itemInfoTimer and not e.Module._spellRefreshPending,"completion releases pending latches")
        check(invalidations>=1000,"readiness invalidates collection owner")
        if combat then check(e.Module._pendingUpdate,"combat readiness records deferred update on every client")end
        combat=false;changed();check(#queue==(bag and 2 or 1),"second burst schedules normally after completion")
        combat=true;local before=updates;for _,t in ipairs(queue)do t.fn()end
        check(updates==before and e.Module._pendingUpdate,"combat entered before delayed callback defers paint")
    end
end
print(("Mount vendor/cache/timer: %d checks; 4 locales, vendor factions, absent/readiness, 5 client gates PASS"):format(checks))
