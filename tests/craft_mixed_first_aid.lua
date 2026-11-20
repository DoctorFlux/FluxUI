-- Production public recipe-list behavior with synthetic native/UI facts.
-- Args: candidate Craft.lua (default live), optional baseline Craft.lua,
-- optional external trace output. No memo, native input or background jobs.
local target=arg[1]or"Inventory/Craft.lua"
local baseline=arg[2]
local tracePath=arg[3]
local function read(p)local f=assert(io.open(p,"rb"));local x=f:read("*a");f:close();return x end
local source=read("ExtraButtonSystem/Engine/_tmp_consumablesmoke.lua")
local marker=assert(source:find("-- PLAYER_LOGIN bag priming",1,true))
local checks,cases,traces=0,0,{}
local function check(v,label)checks=checks+1;assert(v,label)end
local function encode(x)
 if type(x)=="nil"then return"null"elseif type(x)=="number"or type(x)=="boolean"then return tostring(x)
 elseif type(x)=="string"then return string.format("%q",x):gsub("\\\n","\\n")end
 local keys={};for k in pairs(x)do keys[#keys+1]=k end
 table.sort(keys,function(a,b)return tostring(a)<tostring(b)end)
 local out={};for _,k in ipairs(keys)do out[#out+1]=encode(tostring(k))..":"..encode(x[k])end
 return"{"..table.concat(out,",").."}"
end
local function fixture(path)
 local env=setmetatable({arg={[0]="ExtraButtonSystem/Engine/_tmp_consumablesmoke.lua"}},{__index=_G})
 env.io={open=function(p,...)
  if p:gsub("\\","/"):match("Inventory/Craft.lua$")then p=path end
  return io.open(p,...)
 end}
 return assert(load(source:sub(1,marker-1).."\nreturn boot,items","@mixed-first-aid-fixture","t",env))()
end
local patterns={
 {name="alternating",tags={"F","N","U","F","N","U"}},
 {name="none-first-aid",tags={"N","U","N","U"}},
 {name="none-first-aid-or-untagged",tags={"N","N","N"}},
 {name="zero-classifier-matches",tags={"F","N","U"},reject=true},
 {name="duplicate-source-alias",tags={"A","N","A","U","F"}},
 {name="first-aid-name",tags={"B","N","U","B"}},
}
local fields={"recipeID","name","outputItemID","outputLink","legacy","skillLineID","skillName",
 "quantityMin","quantityMax","effective","maxStack","outputPerCraft","craftable","craftableItems"}
local function run(path,family,kind,pattern)
 local boot,items=fixture(path)
 local s=boot(family,family=="era"or family=="anniversary")
 local e,craft=s.env,s.inv.Craft
 local rows,records,alias={},{}
 for i,tag in ipairs(pattern.tags)do
  local r
  if tag=="A"and alias then r=alias
  else
   local id=510000+i
   items[id]={kind=kind,effective=1,health=1,mana=1,maxStack=20}
   r={recipeID=9000+i,name="Row "..i,outputItemID=id,outputLink="item:"..id,
    legacy=family=="era"or family=="anniversary",quantityMin="2",quantityMax=3,
    reagents={{itemID=70001,count=1}}}
   if tag=="F"or tag=="A"then r.skillLineID=129;r.skillName="First Aid"
   elseif tag=="B"then r.skillName="First Aid"
   elseif tag=="N"then r.skillLineID=171;r.skillName="Alchemy"
   else r.skillName=""end
   if tag=="A"then alias=r end
  end
  rows[i]=r;records[i]={row=r,tag=tag,effective=i*11}
 end
 s.inv.Professions={ListAllCachedRecipes=function()return rows end}
 s:set(0,1,70001,10);s:bags();s:advance(9)
 local events,classified={},0
 local function log(...)events[#events+1]=table.concat({...},":")end
 e.FluxConsumableClassify.Classify=function(id)
  classified=classified+1;log("classify",id)
  local eff=classified*11
  return{kind=pattern.reject and"confirmedOtherKind"or kind,health=eff,mana=eff,effective=eff}
 end
 e.FluxItemClass={GetStatic=function(id)log("static",id);return{classID=0}end}
 e.Enum=e.Enum or{};e.Enum.Profession={FirstAid=129,Alchemy=171,Tailoring=197}
 e.C_TradeSkillUI=e.C_TradeSkillUI or{}
 e.C_TradeSkillUI.GetProfessionSkillLineID=function(id)log("profession",id);return id end
 local originalCount=craft.GetCraftableCount
 craft.GetCraftableCount=function(reagents)
  log("craft-count",reagents[1].itemID,reagents[1].count)
  return originalCount(reagents)
 end
 local originalYield=craft.GetOutputPerCraft
 craft.GetOutputPerCraft=function(r)log("yield",r.recipeID);return originalYield(r)end
 local score=e.FluxConsumableBest.Score;local originalStack=score.GetMaxStack
 score.GetMaxStack=function(id)log("stack",id);return originalStack(id)end
 local native=e.C_Item and e.C_Item.GetItemCount or e.GetItemCount
 local function nativeCount(...)log("native-count",(select(1,...)));return native(...)end
 if e.C_Item and e.C_Item.GetItemCount then e.C_Item.GetItemCount=nativeCount else e.GetItemCount=nativeCount end
 craft.InvalidateCanCraftCache()
 local list=craft.ListRecipesForKind(kind)
 check(classified==#rows,"every source occurrence is classified")
 local prefer=(kind=="healPotion"and family=="forever")or(kind=="bandage"and family~="retail")
 local selected={}
 if not pattern.reject then
  local firstAid=false
  if prefer then for _,r in ipairs(records)do if r.tag=="F"or r.tag=="A"or r.tag=="B"then firstAid=true end end end
  for _,r in ipairs(records)do
   local aid=r.tag=="F"or r.tag=="A"or r.tag=="B"
   if not prefer or(firstAid and aid)or(not firstAid and r.tag=="U")then selected[#selected+1]=r end
  end
 end
 table.sort(selected,function(a,b)return a.effective>b.effective end)
 check(#list==#selected,"same First Aid/untagged/empty selection")
 local scalar={}
 for i,row in ipairs(list)do
  local expected=selected[i]
  check(row.recipeID==expected.row.recipeID and row.outputItemID==expected.row.outputItemID,"stable compaction retains matching occurrence")
  check(row.effective==expected.effective,"per-occurrence effective remains paired")
  check(row.reagents==expected.row.reagents,"reagent alias remains existing source table")
  check(row~=expected.row,"public output row stays detached")
  check(row.craftable==10 and row.outputPerCraft==2 and row.craftableItems==20,"fresh count and yield remain complete")
  local item={}
  for _,key in ipairs(fields)do item[key]=encode(row[key])end
  item.reagents=encode(row.reagents);scalar[i]=item
 end
 if #list>1 then
  local second=list[2].name;list[1].name="caller mutation"
  check(list[2].name==second,"public rows remain independent")
  check(selected[1].row.name~="caller mutation","caller cannot change cached source record")
 end
 -- Classifier phase precedes any affordability/metadata work. The callback
 -- sequence is compared in full against the exact baseline when supplied.
 local value={rows=scalar,callbacks=events,sourceOccurrences=#rows}
 return encode(value)
end
for _,family in ipairs({"retail","forever","mists","era","anniversary"})do
 for _,kind in ipairs({"healPotion","manaPotion","bandage"})do
  for _,pattern in ipairs(patterns)do
   local label=family.."/"..kind.."/"..pattern.name
   local result=run(target,family,kind,pattern)
   if baseline then check(result==run(baseline,family,kind,pattern),"complete scalar/callback trace parity "..label)end
   cases=cases+1;traces[#traces+1]=label.." "..result
  end
 end
end

local function checkFallback(path, family, replaceGetter, expectDeferred)
    local boot = fixture(path)
    local s = boot(family, family == "era" or family == "anniversary")
    local samples = {
        { name = "Major Healing Potion", match = "healPotion" },
        { name = "Elixir of Health", subclass = 1, match = "healPotion" },
        { name = "Mana Injector", match = "manaPotion" },
        { name = "Elixir of Mana", subclass = 1, match = "manaPotion" },
        { name = "Healing Mana Potion", match = "manaPotion" },
        { name = "Restorative Rejuvenation Potion", match = "healPotion" },
        { name = "Runecloth Bandage", match = "bandage" },
        { name = "Field Dressing", subclass = 7, match = "bandage" },
        { name = "Healing Salve" },
        { name = "Mana Salve" },
        { name = "Northshire Cloth" },
        { name = "Dreamless Sleep Mana Potion", subclass = 1, id = 20002 },
    }
    local records, byID = {}, {}
    for i, sample in ipairs(samples) do
        local itemID = sample.id or 630000 + i
        byID[itemID] = sample
        records[i] = { name = sample.name, recipeID = 630000 + i, outputItemID = itemID,
            reagents = { { itemID = 70001, count = 1 } } }
    end
    local reads = {}
    local function getStatic(itemID)
        reads[#reads + 1] = itemID
        local sample = byID[itemID]
        return sample and { subClassID = sample.subclass }
    end
    s.env.FluxItemClass = { GetStatic = getStatic }
    -- The client loads ItemClass before Craft. Rebind the fixture in that order.
    s.load("Inventory/Craft.lua")
    if replaceGetter then
        s.env.FluxItemClass.GetStatic = function(id) return getStatic(id) end
    end
    s.env.FluxConsumableClassify.Classify = function() return nil end
    s.inv.Professions = { ListAllCachedRecipes = function() return records end }

    for _, kind in ipairs({ "healPotion", "manaPotion", "bandage" }) do
        reads = {}
        local actual = {}
        for _, row in ipairs(s.inv.Craft.ListRecipesForKind(kind)) do
            actual[row.outputItemID] = row.effective
        end
        for id, item in pairs(byID) do
            check((actual[id] == 1) == (item.match == kind), family .. " fallback " .. kind .. ": " .. item.name)
        end
        local expectedReads = expectDeferred and not replaceGetter and kind ~= "bandage" and 2 or 11
        check(#reads == expectedReads, family .. " static reads for " .. kind)
    end
end

for _, family in ipairs({ "retail", "forever", "mists", "era", "anniversary" }) do
    checkFallback(target, family, false, true)
    checkFallback(target, family, true, true)
    if baseline then checkFallback(baseline, family, false, false) end
end

if tracePath then local f=assert(io.open(tracePath,"wb"));f:write(table.concat(traces,"\n").."\n");f:close()end
print(("CRAFT_MIXED_FIRST_AID %d checks; %d cases; paired=%s PASS"):format(checks,cases,tostring(baseline~=nil)))
