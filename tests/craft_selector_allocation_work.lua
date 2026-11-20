-- Real inventory/craft services; native item and profession facts are fixtures.
local function read(path)
    local f = assert(io.open(path, 'rb')); local s = f:read('*a'); f:close(); return s
end
local replacement, baseline, tracePath
for i, v in ipairs(arg or {}) do
    if v == '--craft' then replacement = arg[i + 1] end
    if v == '--baseline' then baseline = true end
    if v == '--trace' then tracePath = arg[i + 1] end
end
local source = read('ExtraButtonSystem/Engine/_tmp_consumablesmoke.lua')
local stop = assert(source:find('-- PLAYER_LOGIN bag priming', 1, true))
local fixture = setmetatable({ arg = { [0] = 'ExtraButtonSystem/Engine/_tmp_consumablesmoke.lua' } }, { __index = _G })
fixture.io = { open = function(path, ...)
    if replacement and path:gsub('\\', '/'):sub(-#'Inventory/Craft.lua') == 'Inventory/Craft.lua' then path = replacement end
    return io.open(path, ...)
end }
local boot, items = assert(load(source:sub(1, stop - 1) .. 'return boot, items', '@craft-selector-fixture', 't', fixture))()
local checks, failures = 0, 0
local trace = {}
local function rowTrace(label, row)
    local values = {label}
    for _, key in ipairs({'recipeID','name','outputItemID','outputLink','legacy','skillLineID','skillName',
        'quantityMin','quantityMax','effective','maxStack','outputPerCraft','craftable','craftableItems'}) do
        values[#values+1] = tostring(row and row[key])
    end
    for _, reagent in ipairs(row and row.reagents or {}) do
        values[#values+1] = table.concat({tostring(reagent.itemID),tostring(reagent.count),tostring(reagent.name)},':')
    end
    trace[#trace+1] = table.concat(values,'|')
end
local function check(value, message)
    checks = checks + 1
    if not value then failures = failures + 1; print('FAIL '..message) end
end
local function provider(s)
    local char, callbacks = { bags = {} }, {}
    s.env.Syndicator = { Constants = { AllBagIndexes = {0,1}, AllBankIndexes = {} },
        API = { IsReady = function() return true end, GetCurrentCharacter = function() return 'Fixture-Realm' end,
            GetCharacter = function() return char end },
        CallbackRegistry = { RegisterCallback = function(_, event, fn) callbacks[event] = fn end } }
    s.load('Inventory/Syndicator/Adapter.lua')
    s.inv.Syndicator.RebuildAll = function() s.inv.Syndicator.RebuildBags() end
    s.inv.Syndicator.Start()
    function s:publish()
        for i, bag in ipairs({0,1}) do
            char.bags[i] = {}
            for slot, rec in pairs(self.slots[bag]) do
                char.bags[i][slot] = { itemID = rec.itemID, itemCount = rec.stackCount, itemLink = rec.hyperlink }
            end
        end
        callbacks.BagCacheUpdate(nil, 'Fixture-Realm', { bags = { [0]=true, [1]=true } })
        self:advance(.5)
    end
end
local rawLine
do
    local line=0
    for text in (read(replacement or 'Inventory/Craft.lua')..'\n'):gmatch('(.-)\n') do
        line=line+1
        if text:find('local preferFirstAid =',1,true) then rawLine=line end
    end
end
assert(rawLine,'private preparation observation point')
local scenarios = 0
for _, family in ipairs({'retail','forever','era','anniversary','mists'}) do
    for _, mode in ipairs({'builtin','syndicator'}) do
        for _, kind in ipairs({'healPotion','manaPotion','bandage'}) do
            local legacy = family == 'era' or family == 'anniversary'
            local s = boot(family, legacy)
            if mode == 'syndicator' then provider(s) end
            local craft, rows = s.inv.Craft, {}
            local trackedList=craft.ListRecipesForKind
            local sorts,comparators,wrappers=0,{},{}
            s.env.table=setmetatable({sort=function(values,less)
                if debug.getinfo(2,'f').func==trackedList then
                    sorts=sorts+1;comparators[less]=true
                end
                return table.sort(values,less)
            end},{__index=table})
            local function observeRaw(_,line)
                if line~=rawLine or debug.getinfo(2,'f').func~=trackedList then return end
                local i=1
                while true do
                    local name,value=debug.getlocal(2,i)
                    if not name then return end
                    if name=='raw' then
                        for _,box in ipairs(value) do
                            if type(box)=='table' and box.recipe then wrappers[box]=true end
                        end
                        return
                    end
                    i=i+1
                end
            end
            local skill = kind == 'bandage' and (family == 'retail' and 197 or 129)
                or (kind == 'healPotion' and family == 'forever' and 129 or 171)
            for i=1,100 do
                local id = 100000+i
                items[id] = { kind=kind, effective=i, health=i, mana=i, maxStack=20 }
                rows[i] = { recipeID=9000+i, name='Recipe '..i, outputItemID=id, skillLineID=skill,
                    legacy=legacy, quantityMin=2, quantityMax=2,
                    reagents={ {itemID=70001,count=i}, {itemID=70002,count=1} } }
            end
            s.inv.Professions = { ListAllCachedRecipes=function() return rows end }
            s.env.FluxItemClass = { GetStatic=function(id) return {classID=items[id] and 0 or 7} end }
            local reads, original = 0, legacy and s.env.GetItemCount or s.env.C_Item.GetItemCount
            local function counted(...) reads=reads+1; return original(...) end
            if legacy then s.env.GetItemCount=counted else s.env.C_Item.GetItemCount=counted end
            local function set(have)
                s:set(0,1,70001,have); s:set(0,2,70002,200)
                if s.publish then s:publish() else s:bags() end
                s:advance(9); craft.InvalidateCanCraftCache(); reads=0
            end
            local label=family..' '..mode..' '..kind
            for _, have in ipairs({200,20,0}) do
                set(have)
                if have==200 then debug.sethook(observeRaw,'l') end
                local best=craft.GetBestCraftable(kind)
                if have==200 then
                    debug.sethook()
                    local allocated=0;for _ in pairs(wrappers) do allocated=allocated+1 end
                    check(allocated==(baseline and 100 or 0),label..' private wrapper allocation budget')
                end
                local n=math.min(100,have)
                check((best and best.outputItemID or 0)==(n>0 and 100000+n or 0),label..' highest affordable '..have)
                rowTrace(label..' best '..have,best)
                if best then
                    check(best.recipeID==9000+n and best.craftable==math.floor(have/n),label..' quantity facts')
                    check(best.outputPerCraft==2 and best.craftableItems==2*best.craftable,label..' output yield')
                end
                local native=reads
                local expected=100+n
                check(native==expected,label..' native work '..have..' actual='..native..' expected='..expected)
                check(craft.BagChangesAffectKind(kind,{[70001]=true}) and craft.BagChangesAffectKind(kind,{[70002]=true}),label..' full dependencies')
                check(not craft.BagChangesAffectKind(kind,{[79999]=true}),label..' unrelated material admission')
                for _=1,20 do craft.GetBestCraftable(kind) end
                check(reads==native,label..' cache retains original bag-generation cadence')
                print(('CRAFT_SELECTOR %s %s %s have=%d native=%d selected=%d'):format(family,mode,kind,have,native,best and best.outputItemID or 0))
                scenarios=scenarios+1
            end
            set(200)
            local list=craft.ListRecipesForKind(kind)
            check(#list==100 and reads==200,label..' public full list stays complete')
            for i,entry in ipairs(list) do
                check(entry.outputItemID==100101-i and entry.craftable==math.floor(200/(101-i)),label..' public list row '..i)
                rowTrace(label..' public '..i,entry)
            end
            local owned=craft.ListRecipesForKind
            local seamCalls=0
            craft.ListRecipesForKind=function() seamCalls=seamCalls+1; return {{outputItemID=777,recipeID=778,craftable=3,outputPerCraft=4,reagents={{itemID=70001,count=1}}}} end
            craft.InvalidateCanCraftCache(); local external=craft.GetBestCraftable(kind)
            check(seamCalls==1 and external.outputItemID==777 and external.craftableItems==12,label..' public list override preserved')
            rowTrace(label..' override',external)
            craft.ListRecipesForKind=owned
            local ownedCount, ownedYield = craft.GetCraftableCount, craft.GetOutputPerCraft
            local countCalls=0
            craft.GetCraftableCount=function(...) countCalls=countCalls+1; return ownedCount(...) end
            craft.InvalidateCanCraftCache(); reads=0
            check(craft.GetBestCraftable(kind).outputItemID==100100 and countCalls==100 and reads==200,label..' public craft-count override full path')
            craft.GetCraftableCount=ownedCount
            local yieldCalls=0
            craft.GetOutputPerCraft=function(...) yieldCalls=yieldCalls+1; return ownedYield(...) end
            craft.InvalidateCanCraftCache(); reads=0
            check(craft.GetBestCraftable(kind).outputItemID==100100 and yieldCalls==100 and reads==200,label..' public yield override full path')
            craft.GetOutputPerCraft=ownedYield
            for _, key in ipairs({'GetLiveCount','GetCount','IsReliable'}) do
                local saved=s.inv[key]
                s.inv[key]=function(...) return saved(...) end
                craft.InvalidateCanCraftCache(); reads=0
                check(craft.GetBestCraftable(kind).outputItemID==100100 and reads==200,label..' inventory '..key..' override full path')
                s.inv[key]=saved
            end
            local marker={}
            craft.GetCraftableCount=function() error(marker,0) end
            craft.InvalidateCanCraftCache()
            local ok,err=pcall(craft.GetBestCraftable,kind)
            check(not ok and err==marker,label..' craft-count error propagates exactly')
            craft.GetCraftableCount=ownedCount
            craft.GetOutputPerCraft=function() error(marker,0) end
            craft.InvalidateCanCraftCache()
            ok,err=pcall(craft.GetBestCraftable,kind)
            check(not ok and err==marker,label..' yield error propagates exactly')
            craft.GetOutputPerCraft=ownedYield
            craft.InvalidateCanCraftCache()
            check(craft.GetBestCraftable(kind).outputItemID==100100,label..' recovery after override error')
            rows[100].reagents={{name='Unresolved material',count=1}}
            craft.InvalidateCanCraftCache()
            local lower=craft.GetBestCraftable(kind)
            check(lower and lower.outputItemID==100099,label..' unresolved strongest recipe retains lower tier')
            check(craft.BagChangesAffectKind(kind,{[79999]=true}),label..' unknown dependency stays conservative')
            rowTrace(label..' unresolved',lower)
            check(craft.GetBestCraftable('invalid')==nil and #craft.ListRecipesForKind('invalid')==0,label..' invalid kind remains empty')
            local identities=0;for _ in pairs(comparators) do identities=identities+1 end
            check(sorts>1 and identities==(baseline and sorts or 1),label..' stateless comparator allocation budget')
            print(('CRAFT_ALLOCATION %s sorts=%d comparatorIdentities=%d rawWrappers=%d'):format(label,sorts,identities,baseline and 100 or 0))
        end
    end
end
print(('Craft selector: %d checks; %d scenarios; %d failures; native facts mocked'):format(checks,scenarios,failures))
if tracePath then local f=assert(io.open(tracePath,'wb')); f:write(table.concat(trace,'\n')..'\n'); f:close() end
assert(failures==0,'craft selector failure')
