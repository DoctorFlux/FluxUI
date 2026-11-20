-- Full production module: optional rank-build detail must not alter native work.
local function read(path)
    local file=assert(io.open(path,'rb'));local source=file:read('*a');file:close();return source
end
local function compile(source,env)
    if setfenv then local fn=assert(loadstring(source,'@spell-rank-cost'));setfenv(fn,env);return fn end
    return assert(load(source,'@spell-rank-cost','t',env))
end
local source=read(arg[1]or'Bars/SpellRank.lua')
local checks,scenes=0,0
local function check(value,label)checks=checks+1;assert(value,label)end
local function fixture(modern)
    local f={trace={},clocks=0,privacy=0,gets=0,supported=true,times={100,105},remaining=90,events={}}
    local env=setmetatable({}, {__index=_G});env._G=env
    local flux={Bars={},Client={isEra=true},AfterLoad=function()end,AfterLogin=function()end,
        SpellBookChrome={RankChromeAllowed=function()f.trace[#f.trace+1]='supported';return f.supported end},
        Events={Register=function(event,fn)f.events[event]=fn end}}
    local function note(value)f.trace[#f.trace+1]=value end
    flux.Spell={GetName=function(id)note('name'..id);return'Spell'..id end,
        GetSubtext=function(id)note('sub'..id);return'Rank 1'end}
    local function book(index)
        if f.bookHook then f.bookHook(index)end
        if f.failAt==index then error(f.rawError,0)end
        if index==1 then return 101 elseif index==3 then return 102 end
    end
    env.Enum={SpellBookSpellBank={Player=1},SpellBookItemType={Spell=7}}
    if modern then
        env.C_SpellBook={GetSpellBookItemInfo=function(index,bank)
            note('book'..index);check(bank==1,'modern player bank retained')
            local id=book(index);if index==4 then return nil end
            return{itemType=id and 7 or 8,actionID=id}
        end}
        f.expected='supported,book1,name101,sub101,book2,book3,name102,sub102,book4'
    else
        env.GetNumSpellTabs=function()note('tabs');return 2 end
        env.GetSpellTabInfo=function(tab)note('tab'..tab);return'Spells',nil,tab==1 and 0 or 2,tab==1 and 2 or 1 end
        env.GetSpellBookItemInfo=function(index,bank)
            note('legacy'..index);check(bank=='spell','legacy player bank retained')
            local id=book(index);return id and'SPELL'or'FUTURESPELL',id
        end
        f.expected='supported,tabs,tab1,legacy1,name101,sub101,legacy2,tab2,legacy3,name102,sub102'
    end
    env.issecretvalue=function(value)f.privacy=f.privacy+1;return rawequal(value,f.secret)end
    env.issecrettable=function(value)f.privacy=f.privacy+1;return rawequal(value,f.secretTable)end
    env.canaccesstable=function(value)f.privacy=f.privacy+1;return not rawequal(value,f.denied)end
    env.debugprofilestop=function()
        f.clocks=f.clocks+1;if f.clockHook then f.clockHook(f.clocks)end;return f.times[f.clocks]
    end
    local capture={}
    capture.GetActiveWatchReport=function()
        f.gets=f.gets+1;if f.getHook then f.getHook(f.gets)end;return f.active
    end
    capture.WatchStatus=function()
        if f.statusHook then f.statusHook()end
        return{active=f.active~=nil,secondsRemaining=f.remaining}
    end
    flux.PerfCapture=capture
    local exports=compile(source..'\nreturn {build=BuildSpellRankCache,state=function()return spellRankCache,cacheDirty end}',env)('_FluxUI',{Flux=flux})
    check(flux.Bars.SpellRank.cacheCostVersion==1,'loaded module exposes numeric diagnostic version')
    f.trace={};f.env,f.flux,f.capture,f.exports=env,flux,capture,exports
    return f
end
local function complete(f,label)
    f.exports.build()
    local cache,dirty=f.exports.state()
    check(table.concat(f.trace,',')==f.expected,label..' keeps every native query in order')
    check(not dirty and cache.Spell101.spellID==101 and cache.Spell102.spellID==102,label..' completes the original rank cache')
end
local function report()return{durationLimit=120,unrelated={preserved=true}}end
local opaque=setmetatable({}, {__eq=function()error('private equality')end,__lt=function()error('private order')end,
    __tostring=function()error('private format')end})
for _,modern in ipairs{true,false}do
    do
        scenes=scenes+1;local f=fixture(modern);complete(f,'OFF')
        check(f.clocks==0 and f.privacy==0,'OFF has zero clocks and privacy queries')
    end
    do
        scenes=scenes+1;local f=fixture(modern);f.flux.PerfCapture=nil;complete(f,'missing capture')
        check(f.clocks==0 and f.privacy==0,'missing capture performs no optional native reads')
    end
    do
        scenes=scenes+1;local f=fixture(modern);local r=report();f.active=r
        f.times={100,105,110,112,120,129};complete(f,'active first')
        local first=r.rankCacheBuild
        check(first.schemaVersion==1 and first.count==1 and first.lastMs==5 and first.peakMs==5,'first completed build records bounded count and durations')
        check(first.lastAt==30 and first.peakAt==30,'relative time derives from the same active report')
        f.trace={};f.remaining=85;complete(f,'active second')
        check(r.rankCacheBuild.count==2 and r.rankCacheBuild.lastMs==2 and r.rankCacheBuild.peakMs==5,'last changes while peak remains')
        check(r.rankCacheBuild.lastAt==35 and r.rankCacheBuild.peakAt==30 and first.count==1,'completed summary publishes atomically without changing its predecessor')
        f.trace={};f.remaining=80;complete(f,'active third')
        check(r.rankCacheBuild.count==3 and r.rankCacheBuild.peakMs==9 and r.rankCacheBuild.peakAt==40,'later largest build replaces only bounded peak fields')
        local count=0;for _ in pairs(r.rankCacheBuild)do count=count+1 end
        check(count==6 and r.unrelated.preserved,'summary retains only six scalar fields and preserves other diagnostics')
    end
    do
        scenes=scenes+1;local f=fixture(modern);local r=report();f.active=r;f.failAt=2;f.rawError=opaque
        local ok,err=pcall(f.exports.build);local cache,dirty=f.exports.state()
        check(not ok and rawequal(err,opaque),'native build failure preserves exact opaque error')
        check(dirty and cache.Spell101 and not cache.Spell102,'native failure keeps original partial cache and dirty flag')
        check(r.rankCacheBuild==nil and f.clocks==1,'failed build never publishes successful detail')
    end
    local faults={
        {'missing clock',function(f)f.env.debugprofilestop=nil end},
        {'clock throw',function(f)f.env.debugprofilestop=function()f.clocks=f.clocks+1;error(opaque,0)end end},
        {'nil clock',function(f)f.env.debugprofilestop=function()f.clocks=f.clocks+1;return nil end end},
        {'negative clock',function(f)f.times={-1,2}end},
        {'nan clock',function(f)f.times={0/0,2}end},
        {'infinite clock',function(f)f.times={math.huge,math.huge}end},
        {'secret clock',function(f)f.secret=opaque;f.times={opaque,2}end},
        {'backward clock',function(f)f.times={20,19}end},
        {'end clock disappears',function(f)f.bookHook=function(i)if i==1 then f.env.debugprofilestop=nil end end end},
        {'private report',function(f)f.secret=f.active end},
        {'secret table report',function(f)f.secretTable=f.active end},
        {'inaccessible report',function(f)f.denied=f.active end},
        {'metatable report',function(f)setmetatable(f.active,{__index=function()error(opaque,0)end})end},
        {'privacy predicate throw',function(f)f.env.issecretvalue=function()error(opaque,0)end end},
        {'getter throw',function(f)f.capture.GetActiveWatchReport=function()error(opaque,0)end end},
        {'status throw',function(f)f.capture.WatchStatus=function()error(opaque,0)end end},
        {'inaccessible status',function(f)f.capture.WatchStatus=function()f.denied={};return f.denied end end},
        {'private duration',function(f)f.secret=opaque;f.active.durationLimit=opaque end},
        {'invalid remaining',function(f)f.remaining=121 end},
        {'malformed prior summary',function(f)f.active.rankCacheBuild={count='bad',peakMs=3}end},
        {'private prior count',function(f)f.secret=opaque;f.active.rankCacheBuild={count=opaque,peakMs=3}end},
        {'inaccessible prior summary',function(f)f.active.rankCacheBuild={count=1,peakMs=3};f.denied=f.active.rankCacheBuild end},
    }
    for _,case in ipairs(faults)do
        scenes=scenes+1;local f=fixture(modern);local r=report();f.active=r;case[2](f)
        local old=rawget(r,'rankCacheBuild');complete(f,case[1])
        check(rawequal(rawget(r,'rankCacheBuild'),old),case[1]..' drops optional detail and preserves any prior summary')
    end
    for _,seam in ipairs{'begin clock','native build','ending clock','status','capture replacement','stop then restart then stop'}do
        scenes=scenes+1;local f=fixture(modern);local a,b=report(),report();f.active=a
        local function replace()f.active=b end
        if seam=='begin clock'then f.clockHook=function(n)if n==1 then replace()end end
        elseif seam=='native build'then f.bookHook=function(i)if i==1 then replace()end end
        elseif seam=='ending clock'then f.clockHook=function(n)if n==2 then replace()end end
        elseif seam=='status'then f.statusHook=replace
        elseif seam=='capture replacement'then f.clockHook=function(n)if n==2 then f.flux.PerfCapture={GetActiveWatchReport=function()return b end}end end
        else f.clockHook=function(n)if n==2 then f.active=b;f.active=nil end end end
        complete(f,seam)
        check(a.rankCacheBuild==nil and b.rankCacheBuild==nil,seam..' cannot publish into the old or replacement report')
    end
    do
        scenes=scenes+1;local f=fixture(modern);local r=report();f.active=r;f.times={0,0};complete(f,'zero duration')
        check(r.rankCacheBuild.lastMs==0,'valid zero build duration is retained')
    end
    do
        scenes=scenes+1;local f=fixture(modern);local r=report();f.active=r;f.capture.WatchStatus=nil;complete(f,'missing status')
        check(r.rankCacheBuild.count==1 and r.rankCacheBuild.lastAt==nil,'missing optional status retains duration without invented relative time')
    end
    do
        scenes=scenes+1;local f=fixture(modern);f.active=report();f.supported=false;f.exports.build()
        local cache,dirty=f.exports.state()
        check(next(cache)==nil and dirty and f.clocks==0 and f.privacy==0,'unsupported rank client returns before all diagnostic work')
        check(table.concat(f.trace,',')=='supported','unsupported rank gate retains its original early return')
    end
end
print('spell_rank_cost: '..scenes..' scenes; '..checks..' checks PASS; actual module; native query order and raw errors retained; optional finite-watch detail only')
