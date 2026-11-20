-- Whole production catalogue owner through the existing character-cache fixture.
-- Independent alias/rank/revocation/reference/order/callback assertions; native data mocked.
-- Optional first argument selects an owner; second "baseline" records old allocation shape.
local source = arg[1] or "Inventory/Professions.lua"
local baseline = arg[2] == "baseline"
local cancel = arg[3]
local M = {}
function M.cancel(path)
    if not path or path == "" then return end
    local f = io.open(path, "rb")
    if f then f:close(); error("ROOT CANCEL", 0) end
end
function M.boot(source, client, provider)
    local function ownerLoad(path, ...)
        if path:gsub("\\", "/"):match("Inventory/Professions.lua$") then path = source end
        return loadfile(path, ...)
    end
    local export = setmetatable({ FLUX_CHARACTER_RECIPE_FIXTURE_EXPORT = true, loadfile = ownerLoad }, { __index = _G })
    local Fixture = assert(loadfile("tests/character_recipe_cache.lua", "t", export))()
    local _, s, e, P = Fixture(client or "Forever", false, provider == true)
    return s, e, P
end
function M.install(e, P, skills, order, trace)
    e.FluxInvDB.professions = { [P.GetCharacterKey()] = { bySkillLine = skills } }
    local original = e.pairs or pairs
    e.pairs = function(t)
        if t ~= skills then return original(t) end
        local i = 0
        return function()
            i = i + 1
            local key = order[i]
            if key ~= nil then
                if trace then trace[#trace + 1] = "pair:" .. i end
                return key, skills[key]
            end
        end
    end
end
function M.recipe(tag, id, fields)
    local r = { tag = tag, recipeID = id, name = tag }
    for key, value in pairs(fields or {}) do r[key] = value end
    return r
end
function M.sized(e, P, size)
    local a = {}
    for i = 1, size do
        a[i] = M.recipe("r" .. i, i, { learned = true, skillLineID = 171, outputItemID = 100000+i,
            quantityMin = 1, reagents = { { itemID = 200, count = 1 } } })
    end
    local by = { [171] = { source = "open", recipes = a }, Alchemy = { source = "login", recipes = a } }
    e.FluxInvDB.professions = { [P.GetCharacterKey()] = { bySkillLine = by } }
    return a
end
local checks, scenarios, trace = 0, 0, {}
local function check(ok, label) checks = checks + 1; assert(ok, label) end
local function expect(P, wanted, label)
    scenarios = scenarios + 1
    local got = P.ListAllCachedRecipes()
    check(#got == #wanted, label .. ": count")
    for i, row in ipairs(wanted) do check(got[i] == row, label .. ": exact reference/order " .. i) end
    return got
end
local function add(label) trace[#trace + 1] = label end
local function rankCases(e, P)
    local function pair(label, firstFields, secondFields, firstSource, secondSource, firstKey, secondKey, wantFirst)
        local one = M.recipe("one", 11, firstFields)
        local two = M.recipe("two", 11, secondFields)
        firstKey, secondKey = firstKey or "z", secondKey or "a"
        local skills = { [firstKey] = { source = firstSource, recipes = { one } },
            [secondKey] = { source = secondSource, recipes = { two } } }
        M.install(e, P, skills, { firstKey, secondKey })
        expect(P, { wantFirst and one or two }, label)
    end
    pair("complete beats every lower bit", { learned=true,skillLineID="z",outputItemID=100,quantityMin=1,reagents={{}} },
        { craftingData={version=1,complete=true} }, "open", "login")
    pair("flat beats canonical/open/learned", { learned=true,skillLineID="z" },
        { outputItemID=100,quantityMin=1,reagents={{}} }, "open", "login")
    pair("canonical beats open/learned", { learned=true }, { skillLineID="a" }, "open", "login")
    pair("open beats learned", { learned=true }, {}, "login", "open")
    pair("learned bit", {}, { learned=true }, "login", "login")
    pair("lexical tie winner", {}, {}, "login", "login")
    local k1 = setmetatable({}, { __tostring = function() add("equal-key"); return "same" end })
    local k2 = setmetatable({}, { __tostring = function() add("equal-key"); return "same" end })
    pair("equal string keys keep first", {}, {}, "login", "login", k1, k2, true)
    local a,b,c = M.recipe("a",21),M.recipe("b",22),M.recipe("a-new",21,{learned=true})
    M.install(e,P,{ z={recipes={a,b}}, a={recipes={c}} },{"z","a"})
    expect(P,{c,b},"replacement keeps first encountered output slot")
    local later=M.recipe("equal-rank-later",21,{learned=true})
    M.install(e,P,{z={recipes={a}},b={recipes={c}},c={recipes={later}}},{"z","b","c"})
    expect(P,{c},"updated winning key governs a later equal-rank alias")
    local doomed=M.recipe("revoked",31,{craftingData={version=1,complete=true}})
    local legacy=M.recipe("legacy-revoked",31,{legacy=true,skillName="Alchemy"})
    local kept=M.recipe("false-not-revoked",32)
    local notBoolean=M.recipe("one-not-revoked",33)
    local stringID=M.recipe("string-ID","31")
    M.install(e,P,{ z={recipes={doomed,legacy,kept,notBoolean,stringID}},
        a={recipes={},unlearnedRecipeIDs={[31]=true,[32]=false,[33]=1}} },{"z","a"})
    expect(P,{legacy,kept,notBoolean,stringID},"global true revocation/raw-ID type/legacy exemption")
    local n42=M.recipe("numeric",42,{learned=true})
    local s42=M.recipe("text","42",{craftingData={version=1,complete=true}})
    local padded=M.recipe("padded","042")
    local legacy42=M.recipe("42",19,{legacy=true,skillName="recipe",learned=true})
    M.install(e,P,{z={recipes={n42,padded}},a={recipes={legacy42,s42}}},{"z","a"})
    expect(P,{s42,padded},"canonical text and legacy collisions keep the winning reference and first slot")
    M.install(e,P,{z={recipes={legacy42,padded}},a={recipes={n42,s42}}},{"z","a"})
    expect(P,{s42,padded},"mixed identities also agree when the legacy row appears first")
    local fractional=M.recipe("fractional-key","42.0")
    local float=M.recipe("float",42.0,{learned=true})
    M.install(e,P,{a={recipes={n42,float,fractional}}},{"a"})
    expect(P,tostring(42.0)=="42.0" and {n42,float} or {n42,fractional},
        "floating text retains the Lua runtime's original identity")
    local legacyOne=M.recipe("Same legacy name",8,{legacy=true,skillName="Alchemy"})
    local legacyBetter=M.recipe("Same legacy name",9,{legacy=true,skillName="Alchemy",learned=true})
    local legacyOther=M.recipe("Other legacy name",8,{legacy=true,skillName="Alchemy"})
    M.install(e,P,{ z={recipes={legacyOne,legacyOther}}, a={recipes={legacyBetter}} },{"z","a"})
    expect(P,{legacyBetter,legacyOther},"legacy identity uses skill/name")
    local unknown=M.recipe("unknown",nil)
    local unknownBetter=M.recipe("unknown-better",nil,{learned=true})
    M.install(e,P,{ z={recipes={unknown}}, a={recipes={unknownBetter}} },{"z","a"})
    expect(P,{unknownBetter},"nil identity retains original shared identity rule")
    local original=M.recipe("old",44)
    M.install(e,P,{ a={recipes={original}} },{"a"})
    expect(P,{original},"first fresh query")
    local fresh=M.recipe("fresh",44,{learned=true})
    e.FluxInvDB.professions[P.GetCharacterKey()].bySkillLine.a.recipes={fresh}
    expect(P,{fresh},"each query reads changed current records")
    e.FluxInvDB.professions.Other={bySkillLine={ x={recipes={legacyOther}} }}
    local other=P.ListAllCachedRecipes("Other")
    check(#other==1 and other[1]==legacyOther,"explicit other character query")
    check(#P.ListAllCachedRecipes("Absent")==0,"absent character")
end
for _, client in ipairs({"Retail","Forever","MoP","Era","Anniversary"}) do
    for _, provider in ipairs({false,true}) do
        M.cancel(cancel)
        local _,e,P=M.boot(source,client,provider)
        rankCases(e,P)
    end
end
-- Public property callbacks and errors are observed in their original order.
do
    local _,e,P=M.boot(source)
    local fieldValues = { recipeID=91,legacy=false,outputItemID=100,quantityMin=1,
        reagents={{itemID=200,count=1}},skillLineID="z",learned=true,
        craftingData=setmetatable({},{__index=function(_,key) add("craft:"..key);return ({version=1,complete=true})[key]end}) }
    local r=setmetatable({}, {__index=function(_,key) add("row:"..key);return fieldValues[key]end})
    local d=setmetatable({}, {__index=function(_,key) add("data:"..key);if key=="recipes"then return {r} elseif key=="source"then return "open"end end})
    M.install(e,P,{z=d},{"z"},trace)
    expect(P,{r},"metatable record fields")
end
do
    local _,e,P=M.boot(source)
    local a,b=M.recipe("before",101),M.recipe("late",102)
    local rows={a};local calls=0
    local key=setmetatable({}, {__tostring=function()
        calls=calls+1;add("late-key:"..calls)
        if calls==1 then rows[2]=b end
        return "late"
    end})
    M.install(e,P,{[key]={recipes=rows}},{key},trace)
    expect(P,{a,b},"key tostring can append recipe during active traversal")
    check(calls==2,"exact key tostring evaluation count")
end
do
    local _,e,P=M.boot(source)
    local a,b=M.recipe("outer",111),M.recipe("nested",112)
    local entered,calls=false,0
    local key=setmetatable({}, {__tostring=function()
        calls=calls+1;add("reentry-key:"..calls)
        if not entered then
            entered=true;add("nested-enter")
            local got=P.ListAllCachedRecipes("Nested")
            check(#got==1 and got[1]==b,"nested query owns separate private work")
            add("nested-exit")
        end
        return "outer"
    end})
    M.install(e,P,{[key]={recipes={a}}},{key},trace)
    e.FluxInvDB.professions.Nested={bySkillLine={ n={recipes={b}} }}
    expect(P,{a},"tostring reentry retains outer references")
    check(calls==1,"no eager or repeated first-key conversion")
end
do
    local _,e,P=M.boot(source)
    local marker={};local calls=0
    local key=setmetatable({}, {__tostring=function()calls=calls+1;add("raw-key-error");error(marker,0)end})
    M.install(e,P,{[key]={recipes={M.recipe("error",121)}}},{key},trace)
    local ok,err=pcall(P.ListAllCachedRecipes)
    check(not ok and err==marker and calls==1,"raw key error propagated once without wrapping")
end
do
    local _,e,P=M.boot(source)
    local one,two=M.recipe("entered",131),M.recipe("replacement",132)
    local owned=P.ListAllCachedRecipes;local calls=0
    local data=setmetatable({}, {__index=function(_,field)
        add("late-public:"..field)
        if field=="recipes"then
            P.ListAllCachedRecipes=function()calls=calls+1;return {two}end
            return {one}
        end
    end})
    M.install(e,P,{a=data},{"a"},trace)
    local got=owned()
    check(#got==1 and got[1]==one,"entered private builder not rerouted by late public override")
    check(P.ListAllCachedRecipes()[1]==two and calls==1,"next public call observes current override")
end
do
    local _,e,P=M.boot(source)
    local first=M.recipe("first",141);local replacement=M.recipe("later",142)
    local original=e.tostring or tostring;local switched=false
    e.tostring=function(v)
        add("convert:"..type(v)..":"..(type(v)=="number"and original(v)or type(v)=="string"and v or "object"))
        if v=="a" and not switched then
            switched=true
            e.FluxInvDB.professions[P.GetCharacterKey()].bySkillLine.a.recipes={replacement}
        end
        return original(v)
    end
    M.install(e,P,{a={recipes={first}}},{"a"},trace)
    expect(P,{first},"current ipairs array remains captured during late DB mutation")
    expect(P,{replacement},"next query sees late database replacement")
end
do
    local _,e,P=M.boot(source)
    local row=M.recipe("late converter",143)
    local providerTostring=e.tostring or tostring
    local keyCalls=0
    setmetatable(row,{__index=function(_,field)
        if field~="skillLineID" then return nil end
        e.tostring=function(value)
            if value=="a" then keyCalls=keyCalls+1 end
            return providerTostring(value)
        end
        return "a"
    end})
    M.install(e,P,{a={recipes={row}}},{"a"},trace)
    expect(P,{row},"ordinary alias observes a converter replaced while ranking")
    check(keyCalls==3,"late conversion covers skill line, canonical alias and saved alias")
end
-- Inspect only private ephemeral work of the actual production builder at return.
local f=assert(io.open(source,"rb"));local contents=f:read("*a");f:close()
local buildLine,n=0,0
for row in (contents .. "\n"):gmatch("(.-)\n") do
    n = n + 1
    if row:find("local function BuildCachedRecipeCatalogue(", 1, true)
        or row:find("BuildCachedRecipeCatalogue = function(", 1, true) then
        buildLine = n
    end
end
check(buildLine>0,"production builder located")
for _,size in ipairs({0,7,20,121,500,2000})do
    M.cancel(cancel)
    local _,e,P=M.boot(source)
    local wanted=M.sized(e,P,size)
    local locals
    debug.sethook(function(event)
        if event~="return"then return end
        local info=debug.getinfo(2,"S")
        if not info or info.linedefined~=buildLine or info.source:gsub("\\","/")~="@"..source:gsub("\\","/")then return end
        locals={}
        for i=1,40 do local name,value=debug.getlocal(2,i);if not name then break end;locals[name]=value end
    end,"r")
    local ok,got=pcall(P.ListAllCachedRecipes)
    debug.sethook()
    check(ok,"instrumented query succeeds")
    check(#got==size,"sized complete catalogue count")
    local refs={};for _,r in ipairs(got)do refs[r]=true end
    for _,r in ipairs(wanted)do check(refs[r],"sized exact source reference")end
    check(type(locals)=="table" and type(locals.seen)=="table","actual private seen map captured")
    local records,indices=0,0
    for _,value in pairs(locals.seen)do
        if type(value)=="table"then records=records+1 elseif type(value)=="number"then indices=indices+1 end
    end
    local arrays=(type(locals.ranks)=="table"and 1 or 0)+(type(locals.keys)=="table"and 1 or 0)
    print(("WORK size=%d seenRecords=%d seenIndices=%d parallelArrays=%d"):format(size,records,indices,arrays))
    check(records+indices==size,"one private seen identity per output")
    if not baseline then
        check(records==0 and indices==size,"no per-recipe private seen record allocations")
        check(arrays==(size>0 and 2 or 0),"only two nonempty private metadata arrays")
    end
    if indices>0 then
        check(records==0 and arrays==2,"candidate tracking has bounded parallel arrays")
        check(#locals.ranks==size and #locals.keys==size,"parallel metadata covers every output")
    elseif size==0 then check(arrays==0,"empty catalogue creates no parallel arrays")end
end
print("TRACE "..table.concat(trace,"|"))
print(("CATALOGUE_CHECKS %d SCENARIOS %d PASS"):format(checks,scenarios))
