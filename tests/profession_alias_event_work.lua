-- Whole production profession event work, using the existing character fixture.
-- Iteration counts are deterministic desktop work, not CPU/native latency/FPS.
local root=os.getenv('FLUX_AH_ROOT')or'.'
local source=arg[1]or(root..'/Inventory/Professions.lua')
local rawLoad=loadfile
local function envLoad(path,mode,env)
 local chunk,err=rawLoad(path,mode,env)
 if chunk and setfenv and env then setfenv(chunk,env)end
 return chunk,err
end
local function ownerLoad(path,mode,env)
 if path:gsub('\\','/'):match('Inventory/Professions.lua$')then
  env.wipe=env.wipe or function(t)for k in pairs(t)do t[k]=nil end;return t end
  path=source
 end
 return envLoad(path,mode,env)
end
local export=setmetatable({FLUX_CHARACTER_RECIPE_FIXTURE_EXPORT=true,loadfile=ownerLoad},{__index=_G})
local fixture=assert(envLoad(root..'/tests/character_recipe_cache.lua','t',export))()
local checks=0
local function check(v,label)checks=checks+1;assert(v,label)end
local function copy(v)
 if type(v)~='table'then return v end
 local out={};for k,x in pairs(v)do out[k]=copy(x)end;return out
end
local function cached(id,legacy)
 return {recipeID=id,name='Cached'..id,learned=true,outputItemID=id+100000,
  quantityMin=1,quantityMax=1,reagents={{itemID=200,count=1}},legacy=legacy or false,skillName='Other'}
end
local function boot()
 local _,s,e,P,load=fixture('Forever',false,false)
 load('Inventory/Craft.lua')
 s.ids,s.recipeData={},{}
 for i=1,64 do local id=1000+i
  s.ids[i]=id;s.recipeData[id]={name='Learned'..id,output=id+100000,yield=2,learned=true,mats={{200,2}}}
 end
 local function forbidden()error('unexpected action from recipe event')end
 e.C_TradeSkillUI.OpenTradeSkill=forbidden;e.C_TradeSkillUI.CraftRecipe=forbidden
 e.DoTradeSkill=forbidden;e.CastSpellByName=forbidden
 check(P.ForceScanOpen()~=nil,'warm64 actual learned recipes')
 local db=e.FluxInvDB.professions[P.GetCharacterKey()].bySkillLine
 for i=1,100 do local id=500000+i
  s.ids[#s.ids+1]=id;s.recipeData[id]={name='Unknown'..id,output=id+100000,yield=1,learned=false,mats={}}
 end
 return s,e,P,db
end
local function event(s,e,P)
 local calls={info=0,schematic=0,publication=0,flush=0}
 local function observe(owner,key,counter)
  local old=assert(owner[key]);owner[key]=function(...)
   calls[counter]=calls[counter]+1;return old(...)
  end
  return function()owner[key]=old end
 end
 local restoreInfo=observe(e.C_TradeSkillUI,'GetRecipeInfo','info')
 local restoreSchema=observe(e.C_TradeSkillUI,'GetRecipeSchematic','schematic')
 local restoreFlush=observe(s.inventory.Craft,'TryFlushPendingCraft','flush')
 local oldNotify=s.inventory.Notify
 s.inventory.Notify=function(tokens)check(tokens.professions==true,'profession publication token');calls.publication=calls.publication+1 end
 local original=ipairs;local yields=0
 local function counted(list)
  local iterator,state,key=original(list)
  return function(a,b)
   local k,v=iterator(a,b);if k~=nil then yields=yields+1 end;return k,v
  end,state,key
 end
 _G.ipairs=counted
 local ok,err=pcall(P.OnProfessionEvent,'TRADE_SKILL_LIST_UPDATE')
 local owned=_G.ipairs==counted
 if owned then _G.ipairs=original end
 restoreInfo();restoreSchema();restoreFlush();s.inventory.Notify=oldNotify
 check(owned,'iteration observer ownership restored')
 assert(ok,err)
 check(calls.info==164 and calls.schematic==64,'all current native recipe reads retained')
 check(calls.publication==1 and calls.flush==1,'one event publishes and flushes once')
 return yields
end

-- Eight keys: current64pair, unrelated16pair/23pair and two empty aliases.
-- All100false IDs are absent from every cache, so repeated full membership
-- searches have no useful output. Count EVERY ipairs yield during the event.
local s,e,P,db=boot()
for group,size in ipairs({16,23})do for alias=1,2 do
 local rows={};for i=1,size do rows[i]=cached(group*10000+i,false)end
 db['Other'..group..'Alias'..alias]={recipes=rows,name='Other'..group,unlearnedRecipeIDs={}}
end end
db.Empty1={recipes={},name='Empty1'};db.Empty2={recipes={},name='Empty2'}
local first=event(s,e,P)
local repeatWork=event(s,e,P)
check(#P.ListAllCachedRecipes()==103,'absent false IDs retain every learned recipe')
for _,key in ipairs({'Other1Alias1','Other1Alias2','Other2Alias1','Other2Alias2'})do
 check(db[key].unlearnedRecipeIDs[500001]==nil,'unrelated aliases get no invented tombstone')
end

if not math.type then
 local function countRanks()
  local ranks=0
  debug.sethook(function()
   if debug.getinfo(2,'n').name=='RankObservedRecipes' then ranks=ranks+1 end
  end,'c')
  local ok,why=pcall(event,s,e,P)
  debug.sethook()
  assert(ok,why)
  return ranks
 end
 check(countRanks()==1,'a complete reconciled named alias avoids ranking the catalogue again')
 check(db['171'].recipes~=db.Alchemy.recipes,'numeric and named saves retain separate arrays')
 for i,recipe in ipairs(db['171'].recipes)do
  check(rawequal(recipe,db.Alchemy.recipes[i]),'both aliases retain each resolved recipe reference')
 end
 local retained=cached(700001,false)
 db.Alchemy.recipes[#db.Alchemy.recipes+1]=retained
 check(countRanks()==2,'a named alias with unobserved rows takes the existing merge')
 check(db.Alchemy.recipes[#db.Alchemy.recipes]==retained,'an unobserved saved recipe stays in the named alias')
end

-- Direct consumers must retain typed tombstones, legacy rows and relearnt rows.
s,e,P,db=boot()
db.Historical={name='Historical',recipes={copy(db['171'].recipes[1]),cached(500001,false),cached(500001,true),cached(500002,true)},
 unlearnedRecipeIDs={['500001']=false,[500003]=true,['500003']=false}}
event(s,e,P)
local h=db.Historical
check(#h.recipes==3 and h.recipes[1].recipeID==1001 and h.recipes[2].legacy==true and h.recipes[3].legacy==true,'only the modern removed row retires')
check(h.unlearnedRecipeIDs[500001]==true and h.unlearnedRecipeIDs['500001']==false,'new numeric removal preserves separate string value')
check(h.unlearnedRecipeIDs[500002]==nil,'a legacy-only match cannot invent a modern tombstone')
check(h.unlearnedRecipeIDs[500003]==true and h.unlearnedRecipeIDs['500003']==false,'existing typed true/false tombstones retained')
event(s,e,P)
check(#h.recipes==3 and h.recipes[2].legacy==true and h.recipes[3].legacy==true,'repeat event retains historical array order and legacy row')
s.recipeData[500001]={name='Relearn',output=600001,yield=1,learned=true,mats={{200,1}}}
-- This event has65 learned entries, so validate its facts directly.
P.OnProfessionEvent('TRADE_SKILL_LIST_UPDATE')
check(h.unlearnedRecipeIDs[500001]==nil and h.unlearnedRecipeIDs['500001']==false,'relearning clears only the matching numeric tombstone')
check(#h.recipes==4 and h.recipes[2].legacy==true and h.recipes[3].legacy==true and h.recipes[4].recipeID==500001 and not h.recipes[4].legacy,'relearning appends the modern fact without replacing legacy')
-- Check the live scan and publication entry points with a learned-only list.
do
 local reads, publications, filtered, available, makeable = 0, 0, {11}, {[11]=true}, false
 local function configure(state,env)
  state.recipeData[12].learned=false
  state.recipeData[13]={name='Third',output=102,yield=1,learned=false,mats={{200,1}}}
  state.ids={11,12,13}
  local ts=env.C_TradeSkillUI
  local rawInfo=ts.GetRecipeInfo
  ts.GetRecipeInfo=function(id) reads=reads+1;return rawInfo(id) end
  ts.GetAllRecipeIDs=function()return state.ids end
  ts.GetFilteredRecipeIDs=function()return filtered end
  ts.GetShowLearned=function()return true end
  ts.GetShowUnlearned=function()return false end
  ts.GetOnlyShowMakeableRecipes=function()return makeable end
  ts.GetOnlyShowSkillUpRecipes=function()return false end
  ts.GetOnlyShowFirstCraftRecipes=function()return false end
  ts.AreAnyInventorySlotsFiltered=function()return false end
  ts.AnyRecipeCategoriesFiltered=function()return false end
  ts.GetRecipeItemNameFilter=function()return '' end
  ts.IsTradeSkillReady=function()return true end
  ts.IsDataSourceChanging=function()return false end
  env.issecurevariable=function()return true end
  env.Enum.SpellBookSpellBank={Player=0}
  env.C_SpellBook={IsSpellInSpellBook=function(id)return available[id] end}
  env.Professions={AreAllSourcesUnfiltered=function()return true end}
  state.inventory.Notify=function(tokens)if tokens.professions then publications=publications+1 end end
 end
 local _,state,env,recipes=fixture('Forever',false,false,nil,nil,false,configure)
 local function scan(expected,message,reason)
  reads,publications=0,0
  recipes.OnProfessionEvent(reason or 'TRADE_SKILL_LIST_UPDATE')
  check(reads==expected,message..' (reads='..reads..')')
  check(publications==1,'one publication after recipe facts settle')
 end
 available[12],available[13]=false,false
 scan(3,'first scan reads all learned flags')
 scan(1,'unchanged catalogue corroborates prior negatives with the native spellbook')
 available[13]=nil
 scan(2,'uncertain spellbook result reads the live record')
 available[13]=false
 makeable=true
 scan(3,'makeable filter takes the full path')
 makeable=false
 scan(3,'clearing a filter requires a new complete baseline')
 scan(1,'complete filter baseline enables reuse again')
 state.recipeData[12].learned,available[12]=true,true
 scan(5,'spellbook change before filtered list refresh rechecks the entire catalogue')
 check(#recipes.ListRecipesForOutput(101)==1,'newly learned output is published in the same update')
 filtered={11,12}
 scan(3,'a changed learned list takes the full path')
 scan(2,'only the remaining confirmed negative skips the full getter')
 state.recipeData[12].learned,available[12]=false,false
 filtered={11}
 scan(3,'the live unlearn is reconciled through the full path')
 check(#recipes.ListRecipesForOutput(101)==0,'revoked recipe cannot survive either alias')
 scan(3,'explicit learn events always read the full catalogue','NEW_RECIPE_LEARNED')
 recipes.OnProfessionClosed()
 scan(3,'closing the profession clears the verified list')

 local db=env.FluxInvDB.professions[recipes.GetCharacterKey()].bySkillLine
 local source='TRADE_SKILL_DATA_SOURCE_CHANGED'
 recipes.OnProfessionClosed()
 scan(1,'ready source can retain matching saved removals',source)
 check(db['171'].unlearnedRecipeIDs[12] and db['171'].unlearnedRecipeIDs[13]
  and db.Alchemy.unlearnedRecipeIDs[12] and db.Alchemy.unlearnedRecipeIDs[13],
  'both keys still retain the two removals')
 check(next(recipes.GetSkillInfo(171).removedRecipeIDs)==nil,'saved removals are not presented as new observations')
 scan(1,'first list delivery retains the same safe removals')

 db.Historical={recipes={cached(12,false)},unlearnedRecipeIDs={[13]=false}}
 scan(3,'new alias conflicts force both full native reads')
 check(#db.Historical.recipes==0 and db.Historical.unlearnedRecipeIDs[12]==true
  and db.Historical.unlearnedRecipeIDs[13]==true,'existing removals still reconcile new alias conflicts')
 db.Historical={recipes={cached(13,true)}}
 scan(2,'legacy rows also preserve the ordinary observation path',source)
 check(#db.Historical.recipes==1 and db.Historical.recipes[1].legacy,'legacy record remains intact')
 db.Historical=nil

 local before=state.recipeData[12]
 state.recipeData[12]=nil
 scan(1,'an unavailable native record can only retain already saved facts',source)
 check(db['171'].unlearnedRecipeIDs[12]==true and db.Alchemy.unlearnedRecipeIDs[12]==true,
  'missing metadata preserves an existing removal')
 state.recipeData[12]=before
 state.recipeData[12].learned,available[12]=true,true
 scan(5,'spellbook positive beats saved removal even before the filtered list catches up',source)
 check(db['171'].unlearnedRecipeIDs[12]==nil and db.Alchemy.unlearnedRecipeIDs[12]==nil,
  'late list update cannot hide a newly learned recipe')
 check(#recipes.ListRecipesForOutput(101)==1,'newly learned recipe is published on the ready source')
end

print(('Profession alias state facts: %d checks PASS'):format(checks))
check(first<=12000 and repeatWork<=12000,'whole profession event exceeds array-iteration work budget: first='..first..'/repeat='..repeatWork)
print(('Profession alias event work: %d checks PASS; first=%d/repeat=%d ipairs yields; native performance NOT RUN'):format(checks,first,repeatWork))
