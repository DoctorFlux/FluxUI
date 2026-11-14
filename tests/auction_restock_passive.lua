-- Opening prepares only shortages once; passive updates retain query/choice owners.
local checks,profiles=0,0
local function check(value,label)checks=checks+1;assert(value,label)end
local export=setmetatable({FLUX_AH_POTIONS_FIXTURE_EXPORT=true},{__index=_G})
local fixture=assert(loadfile('tests/auction_restock_potions.lua','t',export))()
local function boot(legacy,auctionator,syndicator)
 local A,s,e,best=fixture(legacy,auctionator,syndicator);s.upgradeChoice=nil
 for id,amount in pairs({[400]=100,[401]=300})do
  s.data[id]={name='Dressing '..id,kind='bandage',amount=amount,level=1};s.itemIDsByName[s.data[id].name]=id
  s.books[id]={commodity=not legacy,offers=legacy and{{itemID=id,quantity=20,total=1200}}or{{itemID=id,quantity=20,unitPrice=60}}}
 end
 s.potionCatalog.bandage={browse={{itemKey=e.C_AuctionHouse.MakeItemKey(401),totalQuantity=20,minPrice=60}},offers={{itemID=401,quantity=20,total=1200}}}
 s.entries[3]={isTierRestock=true,tierKind='bandage',target=20};s.bags[400]=19
 best.Persist.MaybeUpdateRef('bandage',{itemID=400,effective=100,source='owned'});A.SetMaxPrice(400,100)
 return A,s,e,best
end
local function queries(s)
 local n=0;for _,key in ipairs({'search','legacySearch','potionBrowse','legacyPotionSearch','moreCommodity','moreItem','moreBrowse','foreignBrowse'})do n=n+(s.calls[key]or 0)end;return n
end
local function open(A,s)s.emit('AUCTION_HOUSE_SHOW');A.Toggle();s.drain()end
local function pulses(s,count)
 for i=1,count do
  s.generation=s.generation+1
  s.emit('BAG_UPDATE_DELAYED')
  local incoming=s.inventoryListeners and s.inventoryListeners['AuctionRestock.Incoming']
  if incoming then incoming({regions={professions=true,mail=true}})end
 end
end
local function options(A,s,e)
 local build;e.FluxOptions={RegisterModuleOptions=function(_,key,fn)if key=='vendor'then build=fn end end}
 assert(loadfile('AddonOptions/FluxOptionsVendor.lua','t',e))('_FluxUI',{Flux=s.flux})
 local controls={};local function walk(node)for key,child in pairs(node.args or{})do controls[key]=child;walk(child)end end;walk(build());return controls
end
for _,client in ipairs({'Retail','Forever','MoP','Era','Anniversary'})do
 local legacy=client=='Era'or client=='Anniversary'
 for _,auctionator in ipairs({false,true})do for _,syndicator in ipairs({false,true})do
  profiles=profiles+1
  local A,s,e,best=boot(legacy,auctionator,syndicator)
  check(A.IsUpgradeEnabled('healPotion')and A.IsUpgradeEnabled('manaPotion')and not A.IsUpgradeEnabled('bandage'),'healing/mana default on;bandage default off')
  local controls=options(A,s,e)
  check(controls.auctionUpgradeHeal.get()and controls.auctionUpgradeMana.get()and not controls.auctionUpgradeBandage.get(),'real registered Restock controls expose each requested default')
  controls.auctionUpgradeHeal.set(nil,false);controls.auctionUpgradeBandage.set(nil,true)
  check(not A.IsUpgradeEnabled('healPotion')and A.IsUpgradeEnabled('manaPotion')and A.IsUpgradeEnabled('bandage'),'each real option changes only its own kind')
  check(s.settings.auctionRestock.upgradePrompts.healPotion==false and s.settings.auctionRestock.upgradePrompts.bandage==true,'per-character choices are saved explicitly')
  controls.auctionUpgradeHeal.set(nil,true);controls.auctionUpgradeBandage.set(nil,false)
  s.bags[100],s.bags[101],s.bags[400]=20,20,20
  open(A,s);pulses(s,30);s.advance(60)
  local stocks={};for _,row in ipairs(A.GetRows(false))do stocks[#stocks+1]=tostring(row.itemID)..':'..tostring(A.Need(row))end
  check(queries(s)==0 and #A.GetUpgradeProposals()==0,'opening with every target filled never searches or asks for upgrades: '..client..' queries='..queries(s)..' rows='..table.concat(stocks,',')..' status='..tostring(A.status))

  A,s,e,best=boot(legacy,auctionator,syndicator);s.bags[101],s.bags[400]=20,20
  open(A,s)
  local proposals=A.GetUpgradeProposals();local pending=proposals[1]
  check(#proposals==1 and pending.kind=='healPotion'and not s.searchedIDs[300]and not s.searchedIDs[401],
   'opening scans only the missing healing target;filled mana/bandage tiers are skipped')
  local card;for _,cell in ipairs(A.frame.cells)do if cell.upgrade and cell.upgrade.proposal==pending then card=cell.upgrade end end
  local shown,hidden=0,0;card:HookScript('OnShow',function()shown=shown+1 end);card:HookScript('OnHide',function()hidden=hidden+1 end)
  local enableWrites=0
  for _,key in ipairs({'upgrade','keep','blacklist'})do
   local control=card[key];local set=control.SetEnabled
   control.SetEnabled=function(self,value)enableWrites=enableWrites+1;return set(self,value)end
  end
  local before,frames=queries(s),s.frames
  s.recipeItems={[100]=true};s.recipes={{recipeID=700,outputItemID=100,name='Known recipe',learned=true,legacy=true,quantityMin=1,reagents={{itemID=500,count=1}}}}
  for i=1,30 do s.bags[500]=i%2==0 and 20 or 0;pulses(s,1)end
  s.advance(60);pulses(s,30)
  check(queries(s)==before and A.GetUpgradeProposals()[1]==pending and card.proposal==pending,'recipe/material/bag/mail changes and expired prices cannot restart searches or replace a pending choice')
  check(shown==0 and hidden==0 and s.frames==frames and enableWrites==0,'passive pulses cause zero card hide/show transitions,enabled-state writes or frame allocations')
  check(card.keep:GetText()=='Keep'and card.blacklist:GetText()=='Block'and card.keep:GetWidth()==36 and card.blacklist:GetWidth()==42,'short native action labels fit the compact row with separate hit regions')
  A.Settings().upgradePrompts.healPotion=false
  check(not A.ResolveUpgrade(pending,'upgrade')and best.GetBestRef('healPotion').itemID==100,'a preference imported while a choice is open prevents stale tier acceptance')
  A.Settings().upgradePrompts.healPotion=true
  A.SetUpgradeEnabled('healPotion',false)
  check(#A.GetUpgradeProposals()==0 and not A.ResolveUpgrade(pending,'upgrade'),'disabling a type retires its stale actions and keeps the current restock tier')
  A.SetPreferCrafting(false);s.books[100].offers[1].quantity=1;s.books[100].offers[1].total=20
  s.press();s.drain()
  check(A.offer and A.offer.itemID==100 and #A.GetUpgradeProposals()==0 and best.GetBestRef('healPotion').itemID==100,'disabled upgrades still allow current-tier restocking after the user presses Buy next')

  A,s,e,best=boot(legacy,auctionator,syndicator)
  A.SetUpgradeEnabled('healPotion',false);A.SetUpgradeEnabled('manaPotion',false)
  open(A,s)
  check(not s.calls.potionBrowse and not s.calls.legacyPotionSearch and #A.GetUpgradeProposals()==0,'all disabled kinds skip upgrade discovery while ordinary price planning runs')

  A,s,e,best=boot(legacy,auctionator,syndicator)
  s.entries={s.entries[3]};A.SetUpgradeEnabled('bandage',true);open(A,s)
  check(#A.GetUpgradeProposals()==1 and A.GetUpgradeProposals()[1].kind=='bandage','bandage upgrade discovery can be enabled independently')
  A.frame:Hide();A.frame:Show();s.drain()
  check(A.IsUpgradeEnabled('bandage')and #A.GetUpgradeProposals()==1,'saved bandage opt-in survives closing and reopening the tab')

  A,s,e,best=boot(legacy,auctionator,syndicator)
  A.SetUpgradeEnabled('healPotion',false);A.SetUpgradeEnabled('manaPotion',false);A.SetPreferCrafting(false)
  s.entries={{itemID=100,name='Current item',target=20,restockSource='manual'}}
  s.books[100].offers[1].quantity=1;s.books[100].offers[1].total=20
  s.emit('AUCTION_HOUSE_SHOW');A.Toggle()
  local search=A.search;before=queries(s)
  pulses(s,30)
  check(A.search==search and A.state=='searching'and queries(s)==before,'passive pulses cannot cancel/reissue an in-flight item search')
  s.drain();check(A.offer and A.offer.itemID==100,'the original search still settles to a usable offer')
  s.bags[100],s.generation=20,s.generation+1;pulses(s,30)
  check(not A.offer and queries(s)==before,'a fulfilled shortage clears its offer without sending another query')
  s.advance(60);pulses(s,30)
  check(queries(s)==before,'finished restock work stays idle through later stock and price-age updates')
  s.bags[100],s.generation=19,s.generation+1;pulses(s,30)
  check(queries(s)==before,'a later shortage updates counts without reviving a finished queue')
  s.press();s.drain()
  check(queries(s)==before+1 and A.offer and A.offer.itemID==100,'one player press restarts preparation for that missing item only')

  A,s,e,best=boot(legacy,auctionator,syndicator)
  s.entries={s.entries[3]};s.books[400].offers[1].quantity=1;s.books[400].offers[1].total=60
  if not legacy then e.C_AuctionHouse.GetBrowseResults=nil end
  open(A,s)
  check(A.offer and A.offer.itemID==400 and not A.HasBlockedPotionTargets(),
   'default-off bandage upgrades do not require browse support or block ordinary bandage buying')
 end end
end
print(('AH passive refresh: %d checks PASS/%d profiles;one shortage scan;stable choices;zero passive queries;per-kind defaults/options'):format(checks,profiles))
