-- Execute the real category and quick-attach paths; only native inventory is modeled.
local category=arg[1]or'Mail/CategoryAttach.lua'
local quick=arg[2]or'Mail/QuickAttach.lua'
local baseline=arg[3]=='--baseline'
local checks,totalReads=0,0
local function check(ok,label)checks=checks+1;assert(ok,label)end
local function fixture(family,provider,kind)
 local e=setmetatable({},{__index=_G});e._G=e
 local frames,actions,outgoing={},{},{}
 local cursor=false;local reads=0;local infoReads=0;local metadataReads=0;local combat=kind=='combat'
 local n=kind=='all-match'and 32 or 200
 if kind=='one-free'then for i=1,11 do outgoing[i]=true end end
 if kind=='full'then for i=1,12 do outgoing[i]=true end end
 if kind=='holes'then for i=2,12,2 do outgoing[i]=true end end
 if kind=='cursor'then cursor=true end
 e.Syndicator=provider=='syndicator'and{}or nil
 e.ATTACHMENTS_MAX_SEND=12;e.NUM_BAG_SLOTS=4;e.LE_ITEM_BIND_ON_ACQUIRE=1
 e.CreateFrame=function()
  local f={events={}};frames[#frames+1]=f
  function f:RegisterEvent(name)self.events[name]=true end
  function f:SetScript(name,fn)self[name]=fn end
  return f
 end
 e.SendMailFrame={IsShown=function()return kind~='hidden'end}
 e.InCombatLockdown=function()return combat end
 e.CursorHasItem=function()return cursor end
 e.ClearCursor=function()cursor=false end
 e.HasSendMailItem=function(i)reads=reads+1;return outgoing[i]end
 if kind=='no-api'then e.HasSendMailItem=false end
 e.ClickSendMailItemButton=function()
  if kind=='attach-fails'then return end
  for i=1,12 do if not outgoing[i]then outgoing[i]=true;cursor=false;return end end
 end
 local client={isRetail=family=='retail',isCamelot=family=='forever',isEra=family=='era',isAnniversary=family=='anniversary',isMists=family=='mists'}
 local ns={Flux={Client=client,Container={},Item={},Mail={}}};local c=ns.Flux.Container;local mail=ns.Flux.Mail
 mail.IsEnabled=function()return kind~='disabled'end
 mail.GetSetting=function(_,key)return key=='EnableBag0'end
 c.GetNumSlots=function(bag)return bag==0 and n or 0 end
 c.GetItemInfo=function(bag,slot)
  infoReads=infoReads+1
  if kind=='fills-during-info'and infoReads==1 then for i=1,12 do outgoing[i]=true end end
  return{itemID=slot,isLocked=kind=='locked'or slot%17==0,isBound=kind=='bound'}
 end
 ns.Flux.Item.GetInfo=function(id)
  metadataReads=metadataReads+1
  local match=kind=='all-match'or kind=='one-free'or kind=='holes'or kind=='fills-during-info'or kind=='attach-fails'or id%41==0
  return nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,match and 7 or 0,5,kind=='bind-on-pickup'and 1 or 0
 end
 c.PickupItem=function(bag,slot)
  actions[#actions+1]=bag..':'..slot
  cursor=kind~='pickup-fails'
 end
 assert(loadfile(quick,'t',e))('_FluxUI',ns)
 for _,f in ipairs(frames)do if f.events.MAIL_SHOW then f.OnEvent(f,'MAIL_SHOW')end end
 assert(loadfile(category,'t',e))('_FluxUI',ns)
 if kind=='no-match'then ns.Flux.Item.GetInfo=function()metadataReads=metadataReads+1;return nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,0,0,0 end end
 local added=mail.AttachCategory(7,5)
 check(type(added)=='number'and added>=0 and added<=12,family..' bounded return')
 check(not cursor or kind=='cursor',family..' cursor cleanup')
 if kind=='no-match'then
  check(added==0 and infoReads==200,family..' full native scan retained')
  check(baseline or reads<=212,family..' per-slot availability work budget')
 end
 if kind=='all-match'then check(added==12 and#actions==12,family..' native slots cap')end
 if kind=='one-free'then check(added==1 and#actions==1,family..' last native slot')end
 if kind=='holes'then check(added==6 and#actions==6,family..' sparse native slots')end
 if kind=='full'or kind=='hidden'or kind=='disabled'or kind=='cursor'or kind=='no-api'then check(added==0 and infoReads==0,family..' early stop')end
 if kind=='combat'or kind=='bound'or kind=='locked'or kind=='bind-on-pickup'or kind=='fills-during-info'then check(added==0 and#actions==0,family..' no unsafe pickup')end
 if kind=='bound'or kind=='locked'then check(metadataReads==0,family..' filtered before metadata')end
 if kind=='fills-during-info'then check(infoReads==1,family..' native capacity stays live between slot visits')end
 if kind=='mixed'then check(added==4 and#actions==4,family..' class matching remains exact')end
 if kind=='attach-fails'or kind=='pickup-fails'then check(added==0,family..' failed native operation')end
 local pattern={};for i=1,12 do pattern[#pattern+1]=outgoing[i]and'1'or'0'end
 local trace=family..'/'..provider..'/'..kind..'='..added..';info='..infoReads..';metadata='..metadataReads..';actions='..table.concat(actions,',')..';out='..table.concat(pattern)
 return reads,trace
end
local kinds={'no-match','all-match','one-free','holes','full','hidden','disabled','cursor','no-api','combat','bound','locked','bind-on-pickup','fills-during-info','attach-fails','pickup-fails','mixed'}
for _,family in ipairs({'retail','forever','mists','era','anniversary'})do
 for _,provider in ipairs({'builtin','syndicator'})do
  for _,kind in ipairs(kinds)do
   local reads,trace=fixture(family,provider,kind);totalReads=totalReads+reads;print('TRACE '..trace)
   if kind=='no-match'then print('WORK '..family..'/'..provider..' slotAvailabilityReads='..reads)end
  end
 end
end
print('Mail work: '..checks..' checks passed; availability reads '..totalReads)
