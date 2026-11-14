-- Real parser, Best/persist/vendor, owned bindings, craft and tier owners.
local file=assert(io.open('ExtraButtonSystem/Engine/_tmp_consumablesmoke.lua'))
local source=file:read('*a');file:close()
local stop=assert(source:find('-- PLAYER_LOGIN bag priming',1,true))
local fixtureEnv=setmetatable({arg={[0]='ExtraButtonSystem/Engine/_tmp_consumablesmoke.lua'}},{__index=_G})
local boot,items=assert(load(source:sub(1,stop-1)..'return boot,items','@minimum-fixture','t',fixtureEnv))()
local checks,profiles=0,0
local function check(value,label)checks=checks+1;assert(value,label)end
local function provider(s)
 local char,callbacks={bags={}},{ }
 s.env.Syndicator={Constants={AllBagIndexes={0,1},AllBankIndexes={}},
  API={IsReady=function()return true end,GetCurrentCharacter=function()return 'Fixture-Realm'end,GetCharacter=function()return char end},
  CallbackRegistry={RegisterCallback=function(_,event,fn)callbacks[event]=fn end}}
 s.load('Inventory/Syndicator/Adapter.lua');s.inv.Syndicator.RebuildAll=function()s.inv.Syndicator.RebuildBags()end;s.inv.Syndicator.Start()
 function s:publish()
  for i,bag in ipairs({0,1})do char.bags[i]={};for slot,rec in pairs(self.slots[bag])do
   char.bags[i][slot]={itemID=rec.itemID,itemCount=rec.stackCount,itemLink=rec.hyperlink}
  end end
  callbacks.BagCacheUpdate(nil,'Fixture-Realm',{bags={[0]=true,[1]=true}});self:advance(0.4)
 end
end
local facts={}
for i,kind in ipairs({'healPotion','manaPotion'})do
 local base=880000+i*10
 facts[base+1]={kind=kind,low=600,high=800}
 facts[base+2]={kind=kind,low=500,high=1500}
 facts[base+3]={kind=kind,low=650,high=700}
 for id,data in pairs(facts)do items[id]={kind=data.kind,effective=data.high,name='Restorative '..id}end
end
for _,family in ipairs({'retail','forever','mists','era','anniversary'})do
 for _,providerKind in ipairs({'builtin','syndicator'})do
  profiles=profiles+1
  local s=boot(family,family=='era'or family=='anniversary');if providerKind=='syndicator'then provider(s)end
  local e,best,settings,reads=s.env,s.best,{restockCombat={}},0
  e.UnitLevel=function()return 60 end
  e.FluxRestockSettings={Get=function()return settings end};e.FluxRestock={Inv=s.inv}
  local function metadata(ic)
   ic.GetStatic=function()return {classID=0,subClassID=1}end
   ic.GetClassID=function()return 0 end;ic.GetSubClassID=function()return 1 end
   ic.GetName=function(id)return 'Restorative '..id end
   ic.GetInfo=function(id)return {name=ic.GetName(id),minLevel=1}end
   ic.GetLink=function(id)return 'item:'..id end;ic.GetIcon=function(id)return id end;ic.IsLoaded=function()return true end
   ic.GetTooltipText=function(id)
    reads=reads+1;local d=facts[id];if not d then return end
    return 'Requires Level 35\nRestores '..d.low..' to '..d.high..(d.kind=='healPotion'and' health.'or' mana.')..'\nCooldown 3,600 sec.'
   end
  end
  e.FluxItemClass={};metadata(e.FluxItemClass)
  s.load('Inventory/FluxConsumableClassify.lua');s.load('Inventory/FluxConsumableBest/Persist.lua');s.load('Inventory/FluxConsumableBest/VendorMemory.lua')
  s.load('Inventory/Restock/Core/Tiers/FluxRestockTiers_Init.lua');s.load('Inventory/Restock/Core/Tiers/FluxRestockTiers_Settings.lua');s.load('Inventory/Restock/Core/Tiers/FluxRestockTiers_Match.lua')
  local tiers=e.FluxRestockTiers;local C=e.FluxConsumableClassify
  local tooltip=e.FluxItemClass.GetTooltipText
  local cases={
   {id=881001,text='Restores 1,000 - 2,000 health.',minimum=1000,maximum=2000},
   {id=881002,text='Restores 600–800 mana.',minimum=600,maximum=800},
   {id=881003,text='Restores 600—800 health.',minimum=600,maximum=800},
   {id=881004,text='Restores 10 to 20% of your maximum health.',minimum=50,maximum=100,percent=true},
   {id=881005,text='Restores up to 1200 mana.',minimum=0,maximum=1200},
   {id=881006,text='Restores 0 to 400 health.',minimum=0,maximum=400},
  }
  e.FluxItemClass.GetTooltipText=function(id)for _,case in ipairs(cases)do if case.id==id then return case.text end end;return tooltip(id)end
  for _,case in ipairs(cases)do
   local cls=C.Classify(case.id)
   check(cls and cls.restoreMin==case.minimum and cls.restoreMax==case.maximum,'range separators, thousands, percentages and zero/up-to floors are parsed without item names')
   if case.percent then check(best.Score.EffectiveFromClassify(cls,1000,1000)==100,'percentage potion floor scales with the current resource pool')end
  end
  local static=e.FluxItemClass.GetStatic
  e.FluxItemClass.GetStatic=function(id)if id==881007 then return {classID=0,subClassID=7}elseif id==881008 then return {classID=0,subClassID=5}end;return static(id)end
  local previous=e.FluxItemClass.GetTooltipText
  e.FluxItemClass.GetTooltipText=function(id)
   if id==881007 then return 'Heals 100 to 300 damage over 8 sec.'elseif id==881008 then return 'Restores 100 to 300 health over 20 sec. Remain seated while eating.'end
   return previous(id)
  end
  check(C.Classify(881007).effective==300,'bandage range behavior remains unchanged')
  check(C.Classify(881008).effective==300,'food range behavior remains unchanged')
  for i,kind in ipairs({'healPotion','manaPotion'})do
   local current,bad,good=880001+i*10,880002+i*10,880003+i*10
   local cls=C.Classify(current);check(cls.effective==600 and cls.restoreMin==600 and cls.restoreMax==800,'classifier uses minimum and retains maximum metadata')
   check(C.Classify(bad).effective==500 and C.Classify(good).effective==650,'larger maximum cannot inflate the restore floor')
   local field=kind=='healPotion'and'savedHealPotionTier'or'savedManaPotionTier'
   settings.restockCombat[field]=800
   best.Persist.GetRoot().refs[kind]={itemID=current,effective=800,restoreRaw=800,source='owned'}
   check(best.GetBestRef(kind).effective==600 and best.GetBestRef(kind).restoreBasis=='minimum','saved maximum reference migrates from real tooltip')
   check(tiers._Private.GetSavedTier(kind)==600 and settings.restockCombat[field..'Basis']=='minimum','saved restock threshold migrates to minimum')
   check(not best.Persist.MaybeUpdateRef(kind,{itemID=bad,effective=1500,source='auction'}),'old or external maximum-valued candidate cannot replace the saved floor')
   best.Persist.GetRoot().vendorSeen[bad]={kind=kind,effective=1500}
   local vendor=best.VendorMemory.GetVendorCandidates(kind)
   check(#vendor==1 and vendor[1].effective==500,'remembered merchant output is normalized without revisiting the vendor')
   local classify=C.Classify
   C.Classify=function(id,...)if id~=bad then return classify(id,...)end end
   best.Persist.GetRoot().vendorSeen[bad]={kind=kind,effective=1500}
   check(#best.VendorMemory.GetVendorCandidates(kind)==0 and best.Persist.GetRoot().vendorSeen[bad].effective==1500,
    'an unresolved old vendor maximum remains saved but cannot compete as a verified floor')
   check(not best.Persist.MaybeUpdateRef(kind,{itemID=bad,effective=1500,source='vendor'}),
    'missing item data cannot ratchet a new maximum-valued potion reference')
   C.Classify=classify
   s:set(0,i*2-1,current,3);s:set(0,i*2,bad,3)
  end
  if providerKind=='syndicator'then s:publish()else s:bags()end;s:advance(9)
  for i,kind in ipairs({'healPotion','manaPotion'})do
   local current,bad,good=880001+i*10,880002+i*10,880003+i*10
   local path=kind=='healPotion'and'ExtraButtonSystem/CombatGrid/Buttons/HealPotion.lua'or'ExtraButtonSystem/CombatGrid/Buttons/ManaPotion.lua'
   local btn=s:button(kind,true,path);s:advance(0.4)
   check(btn.ItemId==current and best.GetBestOwned(kind).itemID==current,'real potion button and Best keep the higher minimum')
   check(tiers.GetJunkReferenceTier(kind,nil,600)==0,'lower-minimum carried potion cannot make the current tier automatic junk')
   local recipes={{recipeID=1,outputItemID=bad,name='Effect A',reagents={}},{recipeID=2,outputItemID=current,name='Effect B',reagents={}}}
   s.inv.Professions={ListAllCachedRecipes=function()return recipes end}
   local craft=s.inv.Craft.ListRecipesForKind(kind)
   check(#craft==2 and craft[1].outputItemID==current and craft[1].effective==600,'craft recipe ranking uses the same minimum')
   s:set(1,i,good,1);if providerKind=='syndicator'then s:publish()else s:bags()end;s:advance(0.5)
   check(btn.ItemId==good and best.GetBestOwned(kind).itemID==good,'a genuinely higher minimum promotes through the real button listener')
   check(tiers.GetJunkReferenceTier(kind,nil,600)==650,'a higher carried minimum can justify automatic inferior rules')
  end
  local parses,parse=0,C.ParseFoodWaterRestore
  C.ParseFoodWaterRestore=function(...)parses=parses+1;return parse(...)end
  for i=1,100 do best.GetBestRef('healPotion');best.GetBestRef('manaPotion')end
  check(parses==0,'normalized references reuse classification without repeated restore parsing')
  -- Exercise the real metadata restore cache and the classifier's cold-tooltip route.
  s.load('Inventory/FluxItemClass.lua');metadata(e.FluxItemClass)
  C.InvalidateCache(880011)
  local cache=e.FluxItemClass.GetRestore(880011)
  check(cache.ready and cache.health==800 and cache.minimumH==600,'metadata cache retains separate maximum and minimum axes')
  e.FluxItemClass.GetTooltipText=function()return nil end;C.InvalidateCache(880011)
  check(C.Classify(880011).effective==600,'cold-tooltip classification cannot revert to cached maximum')
  e.FluxItemClass.GetRestore=function()return {ready=true,health=800,mana=0}end;C.InvalidateCache(880011)
  check(C.Classify(880011)==nil,'a legacy cached maximum without a minimum is not accepted as verified potion data')
 end
end

-- Native AH transports + explicit upgrade decisions, all optional integrations.
local exported=setmetatable({FLUX_AH_POTIONS_FIXTURE_EXPORT=true},{__index=_G})
local ahBoot=assert(loadfile('tests/auction_restock_potions.lua','t',exported))()
for _,legacy in ipairs({false,false,false,true,true})do
 for _,auctionator in ipairs({false,true})do for _,syndicator in ipairs({false,true})do
  for _,kind in ipairs({'healPotion','manaPotion'})do
   profiles=profiles+1
   local A,s,e,best=ahBoot(legacy,auctionator,syndicator);s.upgradeChoice=nil;s.bags[100],s.bags[101]=19,19
   s.entries[kind=='healPotion'and 2 or 1].target=0
   local current=kind=='healPotion'and 100 or 101
   local good=kind=='healPotion'and 200 or 301
   local bad=kind=='healPotion'and 201 or 300
   for id,d in pairs(s.data)do d.name='Effect '..id;s.itemIDsByName[d.name]=id end
   s.books[301].offers[1].unitPrice=70;s.books[301].offers[1].total=1400
   for _,catalog in pairs(s.potionCatalog)do
    for _,row in ipairs(catalog.browse)do if row.itemKey.itemID==301 then row.minPrice=70 end end
    for _,row in ipairs(catalog.offers)do if row.itemID==301 then row.total=1400 end end
   end
   e.FluxItemClass.GetStatic=function()return {classID=0,subClassID=1}end
   e.FluxItemClass.GetTooltipText=function(id)
    local d=s.data[id];if not d then return end
    local low,high=d.amount,d.amount
    if id==current then low,high=600,800 elseif id==bad then low,high=500,1500 elseif id==good then low,high=650,700 end
    return 'Requires Level '..d.level..'\nRestores '..low..' to '..high..(d.kind=='healPotion'and' health.'or' mana.')
   end
   assert(loadfile('Inventory/FluxConsumableClassify.lua','t',e))('_FluxUI',{})
   best.Persist.GetRoot().refs[kind]={itemID=current,effective=800}
   s.emit('AUCTION_HOUSE_SHOW');A.Toggle();s.drain()
   local proposal=A.GetUpgradeProposals()[1]
   check(proposal and proposal.candidate.itemID==good and proposal.candidate.effective==650 and best.GetBestRef(kind).effective==600,
    ('AH rejects the lower floor despite its larger maximum and asks for the actual higher floor: kind=%s legacy=%s candidate=%s restore=%s baseline=%s state=%s status=%s')
     :format(kind,tostring(legacy),tostring(proposal and proposal.candidate.itemID),tostring(proposal and proposal.candidate.effective),tostring(best.GetBestRef(kind)and best.GetBestRef(kind).effective),tostring(A.state),tostring(A.status)))
   check(not s.calls.quote and not s.calls.buyStack and not s.calls.confirm,'discovery still cannot buy or accept')
   s.decide(true,kind);s.drain()
   check(best.GetBestRef(kind).itemID==good and best.GetBestRef(kind).effective==650 and not e.FluxJunk.IsExplicitJunk(current),
    'explicit approval saves the minimum tier without a premature manual Junk mark')
  end
 end end
end
print(('Potion minimum restore: %d checks PASS/%d profiles;real parser/cache/Best/buttons/vendor/tiers/craft/AH'):format(checks,profiles))
