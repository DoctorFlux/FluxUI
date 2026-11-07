-- Actual reagent scanner + actual unified restock list; native API/security pending.
local reagentSource='Inventory/SpellReagents.lua'
local spellApiSource='Core/API/Spell.lua'
for i=1,#arg do if arg[i]=='--source' then reagentSource=arg[i+1]elseif arg[i]=='--spell-api' then spellApiSource=arg[i+1]end end
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local measure=false;for i=1,#arg do if arg[i]=='--measure' then measure=true end end
local checks=0
local function check(v,s)checks=checks+1;if not measure then assert(v,s)end end
for _,modern in ipairs({false,true})do
 local e=setmetatable({},{__index=_G});e._G=e;e.UIParent={};e.REAGENTS='Reagents';e.BOOKTYPE_SPELL='spell';e.GetTime=function()return 10 end
 local ids={99,10059,1459,688,3562,698};local names={[3561]='Teleport: City',[10059]='Portal: City',[1459]='Arcane Brilliance',[688]='Summon Imp',[3562]='Teleport: Free',[698]='Ritual of Summoning',[9002]='Unlearned travel',[9003]='Overridden travel',[9004]='Free override'}
 local text={[3561]='Reagents: Rune of Teleportation',[10059]='Reagents: Rune of Portals',[1459]='Reagents: |Hitem:17020|h[Arcane Powder]|h',[688]='Reagents: |Hitem:6265|h[Unknown Shard]|h',[3562]='Travel without reagents',[698]='Reagents: Summoning reagent',[9002]='Reagents: |Hitem:17056|h[Feather]|h',[9003]='Reagents: |Hitem:17056|h[Feather]|h',[9004]='Travel without reagents'}
 local scans={};e.Enum={SpellBookSpellBank={Player=0},SpellBookItemType={Spell=1,Flyout=2}}
 local slots={{3561,0,true},{9002,0,false},{9003,9004,true},{3561,0,true},{9004,0,true}}
 local queue={};e.C_Timer={After=function(_,f)queue[#queue+1]=f end};e.GetItemInfo=function(id)if id=='Summoning reagent' or id==16583 then return 'Summoning reagent','|Hitem:16583|h[Summoning reagent]|h' end end;e.GetSpellInfo=function(id)return names[id]end
 e.Flux={AfterLoad=function()end,Secrets={SafeAccessibleString=function(v)return type(v)=='string'and v or nil end},Inventory={GetUniqueItems=function()return{}end}}
 if modern then
  e.C_Spell={GetSpellInfo=function(id)return{name=names[id]}end};e.C_TooltipInfo={GetSpellByID=function(id)scans[id]=(scans[id]or 0)+1;return{lines={{leftText=text[id]}}}end}
  e.C_Flyout={GetFlyoutInfo=function()return{name='Travel',numSlots=#slots,isKnown=true}end,GetFlyoutSlotInfo=function(_,i)local v=slots[i];return{spellID=v[1],overrideSpellID=v[2],isKnown=v[3],name=names[v[1]],specID=63}end}
  e.C_Item={GetItemNameByID=function()return nil end,GetItemCount=function()return 0 end}
  e.C_SpellBook={GetNumSpellBookSkillLines=function()return 1 end,GetSpellBookSkillLineInfo=function()return{itemIndexOffset=0,numSpellBookItems=#ids}end,GetSpellBookItemInfo=function(i)return{actionID=ids[i],itemType=ids[i]==99 and 2 or 1}end}
 else
  e.GetNumSpellTabs=function()return 1 end;e.GetSpellTabInfo=function()return'Test',nil,0,#ids end;e.GetSpellBookItemInfo=function(i)return ids[i]==99 and 'FLYOUT' or 'SPELL',ids[i]end
  e.GetFlyoutInfo=function()return 'Travel',nil,#slots,true end;e.GetFlyoutSlotInfo=function(_,i)return table.unpack(slots[i])end
 end
 local dirty=true;local S={Refresh=function()local r=dirty;dirty=false;return r end};e.FluxInv={Spells=S};e.FluxRestock={Inv={Spells=S,Notify=function()end,GetCount=function()return 0 end,ForEachBagSlot=function()end}}
 e.FluxVendorAuto={NotifyVendorSettingsChanged=function()end};local saved={restockItems={[17031]={targetQuantity=25,countBank=true},[17032]={targetQuantity=8},[17020]={targetQuantity=7},[16583]={targetQuantity=6},[999]={targetQuantity=3}}};e.FluxRestockSettings={Get=function()return saved end}
 e.CreateFrame=function(kind,name)
  local f={name=name};function f:SetOwner()end;function f:ClearLines()end;function f:GetName()return self.name end;function f:NumLines()return self.spell and 1 or 0 end;function f:SetSpellByID(id)scans[id]=(scans[id]or 0)+1;self.spell=id;e.FluxSpellReagentTipTextLeft1={GetText=function()return text[id]end}end;function f:RegisterEvent()end;function f:SetScript()end;return f
 end
 assert(load(read(spellApiSource),'@'..spellApiSource,'t',e))('test',{Flux=e.Flux})
 assert(load(read(reagentSource),'@'..reagentSource,'t',e))('test',{Flux=e.Flux})
 S.Refresh();local n=0;while #queue>0 do n=n+1;assert(n<100,'warm loop');table.remove(queue,1)()end
 check(S.AreReagentsWarmed(),'reagent warm completes')
 check(S.IsReagentItem(17031),'cold-cache teleport rune indexed')
 check(S.IsReagentItem(17032),'cold-cache portal rune indexed')
 check(not S.IsReagentItem(17056),'unknown and overridden-base flyout costs excluded')
 check(scans[3561]==1,'duplicate known flyout child scanned once')
 check(scans[9004]==(modern and 2 or 1),'duplicate free override scanned once through available tooltip paths')
 if modern then local _,_,_,_,spec=e.Flux.Spell.GetFlyoutSlotInfo(99,1);check(spec==63,'modern slot specialization metadata preserved')end
 check(S.IsReagentItem(17020),'other class spell reagent indexed')
 check(S.IsReagentItem(16583),'non-shard summoning reagent is not guessed to be Soul Shard')
 check(not S.IsReagentItem(6265),'Soul Shard excluded before item name loads')
 check(not S.UsesReagents(3562),'reagent-free travel stays free')
 assert(load(read('Inventory/Restock/Core/FluxRestockList.lua'),'@FluxRestockList.lua','t',e))()
 local list=e.FluxVendorAuto.GetRestockTargetItems({forOptionsPanel=true,forceRefresh=true});local seen={}
 for _,r in ipairs(list)do seen[r.itemID]=r end
 for id,target in pairs({[17031]=25,[17032]=8,[17020]=7,[16583]=6})do check(seen[id] and seen[id].restockSource=='spellReagent','reagent belongs in Preset restock '..id);check(seen[id].target==target,'saved target preserved '..id)end
 check(seen[999]and seen[999].restockSource=='manual','ordinary manual items unchanged')
 check(not seen[6265],'no automatic Soul Shard target')
 check(saved.restockItems[17031].countBank==true,'bank flag retained without migration/reset')
 if measure then
  local start=os.clock();local rows=0
  for i=1,1000 do rows=rows+#e.FluxVendorAuto.GetRestockTargetItems({forOptionsPanel=true,forceRefresh=true})end
  local a={};for id,row in pairs(seen)do a[#a+1]=id..':'..row.restockSource..':'..row.target end;table.sort(a)
  print(('PRESET %s %.3f %d %s'):format(modern and 'modern' or 'legacy',(os.clock()-start)*1000,rows,table.concat(a,',')))
 end
 e.SlashCmdList={};assert(load(read('ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua'),'@TeleportPortal.lua','t',e))()
 e.FluxNCTeleportPortal.SetRestockTarget(17031,40);list=e.FluxVendorAuto.GetRestockTargetItems({forOptionsPanel=true,forceRefresh=true});for _,r in ipairs(list)do if r.itemID==17031 then check(r.target==40 and r.restockSource=='spellReagent','normal setter keeps reagent in Preset restock')end end
 e.FluxNCTeleportPortal.SetRestockTarget(17031,0);local zero=e.FluxVendorAuto.GetRestockTargetItems({forOptionsPanel=true,forceRefresh=true});local found=false;for _,row in ipairs(zero)do if row.itemID==17031 then found=row.target==0 and row.restockSource=='spellReagent'end end;check(found,'zero target remains in Preset restock')
end
print('Spell reagent presets: '..checks..(measure and ' workload checks (classification differences retained)' or ' checks passed')..'; native pending')
