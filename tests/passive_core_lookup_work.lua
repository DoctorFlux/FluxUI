-- Whole production Spell/Secrets modules. Function identities and temporary Lua
-- heap are bounded desktop counters, not native CPU/FPS/retained-memory results.
local root = arg[1] or "."
local measure = arg[2] == "--measure"
local checks = 0
local function check(value, label) checks=checks+1;assert(value,label) end
local function fixture(track)
    local s={native=0,trace={},record=true,hit={},throws={},protected={},callbacks={},override=2,formatted="Formatted",name="Name"}
    local e=setmetatable({},{__index=_G});e._G=e
    local ns={Flux={AfterLoad=function()end}}
    ns._secretsBackend={
        IsSecretValue=function(v)return type(v)=="table" and rawget(v,"secret")==true end,
        CanAccessValue=function(v)return not(type(v)=="table" and rawget(v,"inaccessible"))end,
        IsSecretTable=function(v)return type(v)=="table" and rawget(v,"secretTable")==true end,
        CanAccessTable=function(v)return not(type(v)=="table" and rawget(v,"inaccessible"))end,
        CanAccessSecrets=function()return true end,
    }
    e.pcall=function(fn,...)
        if track then s.protected[fn]=true end
        return pcall(fn,...)
    end
    local function probe(kind,id)
        s.native=s.native+1
        if s.record then s.trace[#s.trace+1]=kind..":"..tostring(id)end
        if s.hook then s.hook(kind,id)end
        if s.throws[kind]then error("temporary native query")end
        local h=s.hit[kind]
        return h and h[id] or false
    end
    e.C_Spell={IsCurrentSpell=function(id)return probe("C",id)end,
        IsAutoRepeatSpell=function(id)return probe("A",id)end}
    e.IsCurrentSpell=function(id)return probe("G",id)end
    e.IsAutoRepeatSpell=function(id)return probe("L",id)end
    assert(loadfile(root.."/Core/API/Secrets.lua","t",e))("_FluxUI",ns)
    assert(loadfile(root.."/Core/API/Spell.lua","t",e))("_FluxUI",ns)
    local spell=ns.Flux.Spell
    spell.GetOverrideSpell=function()return s.override end
    spell.FormatCastAttribute=function()return s.formatted end
    spell.GetName=function()return s.name end
    if track then
        for i=1,30 do
            local key,fn=debug.getupvalue(spell.IsCurrent,i)
            if not key then break end
            if key=="SpellEachIdent"then
                debug.setupvalue(spell.IsCurrent,i,function(id,name,callback)
                    s.callbacks[callback]=true
                    return fn(id,name,callback)
                end)
                s.instrumented=true;break
            end
        end
        assert(s.instrumented,"actual identifier-walk boundary")
    end
    return s,ns.Flux,e
end

for _,client in ipairs({"live","forever","classic","classic_era","classic_anniversary"})do
    local s,f,e=fixture(false);local spell,S=f.Spell,f.Secrets
    check(not spell.IsCurrent(1,"Rank"),client.." no active identifier")
    check(table.concat(s.trace,",")=="C:2,G:2,C:1,G:1,C:Rank,G:Rank,C:Formatted,G:Formatted,C:Name,G:Name",
        "override/raw/rank/formatted/name order and C/global fallback")
    s.trace={};s.override=1;s.formatted="Rank";s.name="Rank"
    check(not spell.IsCurrent(1,"Rank")and#s.trace==4,"identifier deduplication retains exact map-key semantics")
    s.hit.G={[1]=true};s.trace={}
    check(spell.IsCurrent(1,"Rank")and table.concat(s.trace,",")=="C:1,G:1","legacy success short-circuits")
    s.hit.A={[1]=true};s.trace={}
    check(spell.IsAutoRepeat(1,"Rank")and table.concat(s.trace,",")=="A:1","modern autorepeat short-circuits")
    s.hit={};s.throws.C=true;s.hit.G={[1]=true}
    check(spell.IsCurrent(1,"Rank"),"modern exception retains global fallback")
    s.throws={};s.hit={};s.trace={}
    check(not spell.IsCurrent(nil,nil)and#s.trace==0,"missing identity has no probes")
    check(not spell.IsAutoRepeat(nil,"")and#s.trace==0,"empty identity has no probes")
    s.hit.L={Rank=true};s.trace={}
    check(spell.IsAutoRepeat(nil,"Rank")and table.concat(s.trace,",")=="A:Rank,L:Rank","name-only fallback")
    s.hit={G={[1]=0}}
    check(spell.IsCurrent(1),"existing Lua truthiness of native nonboolean zero retained")
    s.hit={};s.override=2;s.formatted="Formatted";s.name="Name"
    local nested=false
    s.hook=function(kind,id)
        if kind=="C"and id==2 and not nested then
            nested=true;s.hit.L={Alt=true}
            check(spell.IsAutoRepeat(nil,"Alt"),"reentrant identifier lookup owns an independent seen map")
            s.hit.G={[1]=true}
        end
    end
    check(spell.IsCurrent(1,"Rank")and nested,"outer lookup survives reentry")
    s.hook=nil;s.hit={};s.trace={}
    s.hook=function(kind,id)
        if kind=="G"and id==2 then e.C_Spell.IsCurrentSpell=function(id)return id==1 end end
    end
    check(spell.IsCurrent(1,"Rank"),"next identity sees synchronous native function replacement")
    s.hook=nil;e.C_Spell=nil;s.hit={G={[2]=true}};s.trace={}
    check(spell.IsCurrent(1,"Rank")and table.concat(s.trace,",")=="G:2","missing modern API retains global current query")
    s.hit={L={[2]=true}};s.trace={}
    check(spell.IsAutoRepeat(1,"Rank")and table.concat(s.trace,",")=="L:2","missing modern API retains global autorepeat query")
    local meta={__eq=function()error("identifier key equality must stay raw")end}
    local first,second=setmetatable({},meta),setmetatable({},meta)
    s.override=first;s.hit={};local beforeQueries=s.native
    check(not spell.IsCurrent(second,"Rank")and s.native==beforeQueries+3,
        "seen map retains distinct table-key identities without equality metamethods")

    check(S.KeepLastNumber("12",7,8)==12,"public number conversion")
    check(S.KeepLastNumber(nil,7,8)==7,"missing value retains last number")
    check(S.KeepLastNumber({secret=true},7,8)==7,"secret value retains last")
    check(S.KeepLastNumber({inaccessible=true},nil,8)==8,"inaccessible value falls back")
    check(S.KeepLastNumber("bad",false,false)==0,"existing fallback default semantics")
    local nan=0/0
    check(S.KeepLastNumber(nil,nan,9)~=S.KeepLastNumber(nil,nan,9),"existing nonfinite last-value policy retained")
    check(S.CoerceNumberLoose("12",9)==12,"loose string arithmetic retained")
    check(S.CoerceNumberLoose(false,9)==9 and S.CoerceNumberLoose(math.huge,9)==9,"failed/nonfinite loose conversion")
    local opaqueOps=0
    local opaque=setmetatable({secret=true},{__add=function()opaqueOps=opaqueOps+1;error("opaque arithmetic")end})
    check(S.CoerceNumberLoose(opaque,9)==9 and opaqueOps==1,"existing contained arithmetic policy retained without new guard semantics")
    local info={isFullUpdate=false,addedAuras={},removedAuraInstanceIDs={},updatedAuraInstanceIDs={}}
    check(S.AuraUpdateInfoIsNoop(info)and not S.AuraUpdateInfoHasSecrets(info),"empty incremental payload")
    info.addedAuras[1]={}
    check(not S.AuraUpdateInfoIsNoop(info),"nonempty aura payload retains refresh")
    info.addedAuras={secretTable=true}
    check(not S.AuraUpdateInfoIsNoop(info)and S.AuraUpdateInfoHasSecrets(info),"secret table is never discarded")
    info.addedAuras=false
    check(not S.AuraUpdateInfoIsNoop(info),"failed list length remains conservative")
    check(not S.AuraUpdateInfoIsNoop({})and not S.AuraUpdateInfoIsNoop({isFullUpdate=true}),"full or omitted full flag policy")
    check(S.AuraUpdateInfoHasSecrets({isFullUpdate={secret=true}}),"secret full-update flag")
    local fields={}
    local payload=setmetatable({isFullUpdate=false},{__index=function(_,key)
        fields[#fields+1]=key;if key=="addedAuras"then return {1}end
    end})
    check(not S.AuraUpdateInfoIsNoop(payload)and table.concat(fields,",")=="addedAuras","list field read short circuit retained")
    local busy=false
    info={isFullUpdate=false,addedAuras=setmetatable({},{__len=function()
        if not busy then busy=true;check(S.AuraUpdateInfoIsNoop({isFullUpdate=false}),"reentrant payload owns its input")end
        return 0
    end})}
    check(S.AuraUpdateInfoIsNoop(info)and busy,"outer payload survives length reentry")
end

local iterations=10000
local function workload(s,f)
    s.record=false
    local info={isFullUpdate=false,addedAuras={},removedAuraInstanceIDs={},updatedAuraInstanceIDs={}}
    for _=1,iterations do
        f.Spell.IsCurrent(1,"Rank");f.Spell.IsAutoRepeat(1,"Rank")
        f.Secrets.KeepLastNumber(nil,7,8);f.Secrets.CoerceNumberLoose(12,9)
        f.Secrets.AuraUpdateInfoIsNoop(info);f.Secrets.AuraUpdateInfoHasSecrets(info)
    end
end
local function size(t)local n=0;for _ in pairs(t)do n=n+1 end;return n end
local s,f=fixture(true);workload(s,f)
local callbacks,protected=size(s.callbacks),size(s.protected)
if not measure then
    check(callbacks==2,"checked spell lookups reuse two callbacks")
    check(protected<12,"numeric/payload protected operations reuse stable callbacks")
end
check(s.native==200000,"native query count and fallback cadence retained")
local memoryState,memoryFlux=fixture(false)
collectgarbage("collect");collectgarbage("stop")
local before=collectgarbage("count");workload(memoryState,memoryFlux)
local heap=collectgarbage("count")-before;collectgarbage("restart")
print(string.format("CORE_LOOKUP|iterations=%d|checkedCallbacks=%d|protectedCallbacks=%d|heapKiB=%.3f|nativeQueries=%d",
    iterations,callbacks,protected,heap,memoryState.native))
print("Passive core lookup: "..checks.." checks PASS; desktop allocation/semantics only, native FPS pending")
