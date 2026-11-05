-- Production mail/auction adapter with native timers/provider mocked.
local source=arg[1] or "Inventory/Syndicator/Adapter.lua"
local checks,failed=0,0
local totals={sorts=0,keys=0,auctionRows=0,auctionMaps=0,auctionPulses=0}
local function check(ok,label)checks=checks+1;if not ok then failed=failed+1;print("FAIL "..label)end end
for _,client in ipairs({"forever","retail","era","anniversary","mists"})do
 local h={now=10,timers={},callbacks={},requests={},sorts=0,keys=0,inventoryFns={},inventoryTokens={}}
 local e=setmetatable({}, {__index=_G});e._G=e
 e.GetTime=function()return h.now end
 e.table=setmetatable({sort=function(...)h.sorts=h.sorts+1;return table.sort(...)end},{__index=table})
 e.tostring=function(v)h.keys=h.keys+1;return tostring(v)end
 e.C_Timer={After=function(delay,fn)h.timers[#h.timers+1]={due=h.now+delay,fn=fn}end}
 local char={mail={},auctions={}}
 for i=1,1000 do
  char.mail[i]={itemID=100+i%3,itemCount=i,itemLink="item:"..(100+i%3)}
  char.auctions[i]={itemID=200+i%3,itemCount=i,itemLink="item:"..(200+i%3)}
 end
 local inv={Syndicator={},HasWarband=function()return false end,Containers={NewItemSetLog=function()return {}end},Store={SetUsesSyndicator=function()end},
  snapshots={mail={byIndex={},counts={},generation=0},auctions={byIndex={},counts={},generation=0}}}
 local flux={Inventory=inv,Scheduler={Request=function(_,token,fn)
  if fn then h.inventoryFns[#h.inventoryFns+1]=fn;h.inventoryTokens[token]=true
  else h.requests[token]=(h.requests[token] or 0)+1 end
 end}}
 local function flushInventory()
  local fns,tokens=h.inventoryFns,h.inventoryTokens;h.inventoryFns,h.inventoryTokens={},{}
  for _,fn in ipairs(fns)do fn(tokens)end
  if tokens.auctions then h.requests.auctions=(h.requests.auctions or 0)+1 end
 end
 e.Syndicator={API={IsReady=function()return true end,GetCurrentCharacter=function()return "Fixture" end,
  GetCharacter=function()return char end},CallbackRegistry={RegisterCallback=function(_,key,fn)h.callbacks[key]=fn end}}
 assert(loadfile(source,"t",e))("_FluxUI",{Flux=flux})
 local a=inv.Syndicator
 a.RebuildAll=function()a.RebuildMail();a.RebuildAuctions()end
 a.Start();check(inv.snapshots.mail.generation==1 and inv.snapshots.auctions.generation==1,"cold snapshots published")
 local mail,auction=inv.snapshots.mail,inv.snapshots.auctions
 h.requests={};h.sorts=0;h.keys=0
 local gen=auction.generation;local rows,maps=0,0
 for i=1,100 do
  local old={};for k,v in pairs(auction.byIndex)do old[k]=v end
  local counts=auction.counts
  a.RebuildMail();h.callbacks.AuctionsCacheUpdate(nil,"Fixture");flushInventory()
  for k,v in pairs(auction.byIndex)do if old[k]~=v then rows=rows+1 end end
  if counts~=auction.counts then maps=maps+1 end
 end
 check(h.sorts==0 and h.keys==0,client.." unchanged mail avoids fingerprint sorting/strings")
 check(rows==0 and maps==0,client.." unchanged listings retain snapshot records/maps")
 check(auction.generation==gen and not h.requests.auctions,"unchanged listings do not publish")
 totals.sorts=totals.sorts+h.sorts;totals.keys=totals.keys+h.keys;totals.auctionRows=totals.auctionRows+rows
 totals.auctionMaps=totals.auctionMaps+maps;totals.auctionPulses=totals.auctionPulses+(h.requests.auctions or 0)
 local function flush()
  local safety=0
  while #h.timers>0 do local t=table.remove(h.timers,1);h.now=t.due;t.fn();flushInventory();safety=safety+1;assert(safety<100)end
 end
 -- Delayed item-link metadata is observable even when item IDs/counts match.
 local oldGen=mail.generation;char.mail[1].itemLink="item:101:updated"
 h.callbacks.MailCacheUpdate(nil,"Fixture")
 check(mail.generation==oldGen,"mail publication keeps existing debounce")
 flush();check(mail.byIndex[1].link==char.mail[1].itemLink and mail.generation==oldGen+1,"mail link-only metadata preserved")
 check(h.requests.mail==1,"changed mail publishes once")
 -- Buyer delivery/seller removal/quantity corrections, including sparse keys.
 local removed=char.auctions[1000];local count=auction.counts[removed.itemID]
 char.auctions[1000]=nil;h.requests={};h.callbacks.AuctionsCacheUpdate(nil,"Fixture");flushInventory()
 check(auction.counts[removed.itemID]==count-removed.itemCount,"sale removes listed quantity")
 check(h.requests.auctions==1,"sale publishes once at its inventory tier")
 char.auctions[100000]={itemID="900",count=7,link="item:900"};h.callbacks.AuctionsCacheUpdate(nil,"Fixture");flushInventory()
 check(auction.byIndex[100000].count==7 and auction.counts[900]==7,"sparse listing and legacy fields retained")
 char.auctions[100000].count=0;h.callbacks.AuctionsCacheUpdate(nil,"Fixture");flushInventory()
 check(auction.counts[900]==0,"zero count retained")
 char.mail[100000]={itemID=901,itemCount=4,itemLink="item:901"}
 h.requests={};for i=1,20 do h.callbacks.MailCacheUpdate(nil,"Fixture")end
 check(not h.requests.mail,"purchase callbacks remain coalesced")
 flush();check(mail.counts[901]==4 and h.requests.mail==1,"purchase delivery snapshot publishes once")
 local after=mail.generation;h.callbacks.MailCacheUpdate(nil,"Fixture");flush()
 check(mail.generation==after,"duplicate inbox/close refresh remains quiet")
 after=auction.generation;h.callbacks.AuctionsCacheUpdate(nil,"OtherCharacter")
 check(auction.generation==after,"foreign character callback ignored")
 char.mail={};char.auctions={};a.RebuildMail();a.RebuildAuctions()
 check(next(mail.byIndex)==nil and next(mail.counts)==nil and next(auction.byIndex)==nil,"empty snapshots clear removed contents")
end
print(string.format("Syndicator lists: %d checks, %d failures; stable sorts=%d keys=%d auction row replacements=%d maps=%d pulses=%d",
 checks,failed,totals.sorts,totals.keys,totals.auctionRows,totals.auctionMaps,totals.auctionPulses))
if failed>0 then os.exit(1)end
