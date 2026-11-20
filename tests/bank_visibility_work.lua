-- Entire production Init.lua and Builtin/Bank.lua with native frame/PIM seams.
-- Optional exact Init.lua path and external cancellation path; no client access.
local source=arg[1]or"Inventory/Init.lua"
local cancel=arg[2]
local checks,failures,scenarios=0,0,0
local function cancelled()
 if cancel then local f=io.open(cancel,"rb");if f then f:close();error("root CANCEL",0)end end
end
local function eq(a,b,why)
 checks=checks+1
 if a~=b then failures=failures+1;print("FAIL "..why.." got="..tostring(a).." expected="..tostring(b))end
end
local function copy(t)
 if type(t)~="table"then return t end
 local o={};for k,v in pairs(t)do o[k]=copy(v)end;return o
end
local function equal(a,b)
 if type(a)~=type(b)then return false end
 if type(a)~="table"then return a==b end
 for k,v in pairs(a)do if not equal(v,b[k])then return false end end
 for k in pairs(b)do if a[k]==nil then return false end end
 return true
end
local function boot(family,provider)
 cancelled()
 local h={now=100,events={},timers={},frames={},pim={},work={},family=family,provider=provider}
 local function stat(k)h.work[k]=(h.work[k]or 0)+1 end
 local e=setmetatable({}, {__index=_G});e._G=e;e.SlashCmdList={}
 e.GetTime=function()return h.now end;e.InCombatLockdown=function()return false end
 e.wipe=function(t)for k in pairs(t)do t[k]=nil end;return t end
 local function effective(f)return f.shown and(not f.parent or effective(f.parent))end
 local function frame(shown,parent,label)
  local f={shown=shown,parent=parent,label=label,hooks={},scripts={}}
  function f:IsShown()stat(label.."Shown");if self.shownError then error(self.shownError,0)end;return self.shown end
  function f:IsVisible()stat(label.."Visible");if self.visibleError then error(self.visibleError,0)end;return effective(self)end
  function f:HookScript(k,fn)self.hooks[k]=self.hooks[k]or{};self.hooks[k][#self.hooks[k]+1]=fn end
  function f:SetScript(k,fn)self.scripts[k]=fn end
  function f:RegisterEvent()end;function f:UnregisterEvent()end
  function f:Show()self.shown=true end;function f:Hide()self.shown=false end
  function f:GetName()return self.label end
  h.frames[#h.frames+1]=f;return f
 end
 h.ui=frame(true,nil,"UIParent");h.bank=frame(false,h.ui,"BankFrame")
 h.panel=frame(true,h.bank,"BankPanel");e.BankFrame,e.BankPanel=h.bank,h.panel
 e.CreateFrame=function()return frame(true,h.ui,"owned")end
 e.Enum={PlayerInteractionType={Banker=8,CharacterBanker=67,AccountBanker=68,Auctioneer=21}}
 e.C_PlayerInteractionManager={IsInteractingWithNpcOfType=function(kind)stat("pim");return h.pim[kind]or false end}
 local function after(dt,fn)h.timers[#h.timers+1]={at=h.now+dt,fn=fn};stat("timer")end
 e.C_Timer={After=after}
 local client={isRetail=family=="retail",isForever=family=="forever",isCamelot=family=="forever",isMists=family=="mists",isEra=family=="era",isAnniversary=family=="anniversary"}
 local flux={Client=client,Cap={},Module={Register=function()end},
  Events={Register=function(k,fn)h.events[k]=h.events[k]or{};h.events[k][#h.events[k]+1]=fn end},
  Scheduler={Register=function()end,Request=function()stat("scheduler")end},
  Timer={After=after},Safecall=function(fn,...)return fn(...)end,
  Optional={Get=function()return{loaded=provider=="syndicator"}end}}
 e.Flux=flux
 e._FluxUI_CharSavedVars={Bank={charCounts={[1000]=5},warCounts={[2000]=7},chargeCounts={[3000]=2}}}
 local ns={Flux=flux};h.env,h.flux,h.ns=e,flux,ns
 assert(loadfile(source,"t",e))("_FluxUI",ns)
 local inv=flux.Inventory;h.inv=inv
 inv.Containers={Invalidate=function()stat("invalidate")end,
  IsCarriedBag=function(bag)return bag==0 end,
  IsBankContainer=function(bag)return bag==100 end,
  IsWarbandBankContainer=function()return false end}
 assert(loadfile("Inventory/Builtin/Bank.lua","t",e))("_FluxUI",ns)
 inv.Builtin.Start=function()inv.source="builtin"end
 inv.Syndicator.Start=function()inv.source="syndicator"end
 e.Syndicator={CallbackRegistry={}}
 inv.Start()
 inv.snapshots.bank.byBag={[100]={[1]={itemID=1000,count=5,link="item:1000"}}}
 h.view=frame(false,h.ui,"Baganator_CategoryViewBankViewFrameblizzard")
 e.FluxBaganatorCompat={ForEachBaganatorBankView=function(fn)fn(h.view)end}
 e.C_Item={GetItemCount=function()stat("nativeCount");error("count read forbidden in access gate",0)end}
 flux.Item={GetCount=e.C_Item.GetItemCount}
 function h:emit(k,...)
  local list=self.events[k]or{}
  for i=1,#list do list[i](k,...)end
 end
 function h:hideParent()
  self.bank.shown=false
  for _,fn in ipairs(self.bank.hooks.OnHide or{})do fn(self.bank)end
 end
 function h:dueNow()
  local waiting=self.timers;self.timers={}
  for _,t in ipairs(waiting)do if t.at<=self.now then t.fn()else self.timers[#self.timers+1]=t end end
 end
 function h:cached()
  return copy({snapshots=self.inv.snapshots,saved=self.env._FluxUI_CharSavedVars})
 end
 function h:gates(label,open,live,keep)
  scenarios=scenarios+1
  local data=self:cached()
  local b,w=self.inv.snapshots.bank.counts,self.inv.snapshots.warband.counts
  eq(self.inv.IsBankOpen(),open,label.." open")
  eq(self.inv.IsBankLive(),live,label.." live")
  eq(self.inv.CanTakeFromBank(),live,label.." canTake")
  eq(self.inv.ShouldKeepBankOpen(),keep,label.." keep")
  eq(equal(data,self:cached()),true,label.." leaves all snapshots/saved values")
  eq(self.inv.snapshots.bank.counts==b,true,label.." bank map identity")
  eq(self.inv.snapshots.warband.counts==w,true,label.." account map identity")
  eq(self.work.nativeCount or 0,0,label.." no aggregate native count read")
 end
 return h
end
for _,family in ipairs({"retail","forever","mists","era","anniversary"})do
 for _,provider in ipairs({"builtin","syndicator"})do
  local prefix=family.."/"..provider.."/"
  local h=boot(family,provider)
  h:gates(prefix.."hidden-parent-child-shown",false,false,false)
  eq(h.panel:IsShown(),true,prefix.."native model child shown")
  eq(h.panel:IsVisible(),false,prefix.."native model child effectively hidden")
  h.pim[21]=true;h:gates(prefix.."auctioneer",false,false,false)
  for _,kind in ipairs({8,67,68})do
   local p=boot(family,provider);p.pim[kind]=true
   p:gates(prefix.."physical-PIM-"..kind,true,true,true)
   p.inv.snapshots.bank.counts[1000]=nil;p.inv.snapshots.bank.byBag[100][1]=nil
   p:gates(prefix.."physical-empty-PIM-"..kind,true,true,true)
  end
  local f=boot(family,provider);f.bank.shown=true;f.panel.shown=false
  f:gates(prefix.."native-parent-shown",true,true,true)
  local standalone=boot(family,provider);standalone.panel.parent=standalone.ui
  standalone:gates(prefix.."visible-panel",true,true,true)
  local noframe=boot(family,provider);noframe.env.BankFrame=nil;noframe.env.BankPanel=nil
  noframe:gates(prefix.."missing-native-frames",false,false,false)
  noframe.env.C_PlayerInteractionManager=nil
  noframe:gates(prefix.."missing-PIM-and-frames",false,false,false)
  local cached=boot(family,provider);cached.view.shown=true
  cached:gates(prefix.."cached-Baganator",true,false,true)
  cached.view.liveBankActive=true
  cached:gates(prefix.."live-Baganator-field",true,true,true)
  cached.view.liveBankActive=false;cached.view.currentTab={isLive=true,isLocked=false}
  cached:gates(prefix.."live-Baganator-tab",true,true,true)
  cached.view.currentTab.isLocked=true
  cached:gates(prefix.."locked-Baganator-tab",true,false,true)
  cached.pim[8]=true
  cached:gates(prefix.."cached-Baganator-precedence-over-PIM",true,false,true)
  local latched=boot(family,provider);latched.inv.SetBaganatorBankLive(true)
  latched:gates(prefix.."Baganator-live-latch",true,true,true)
  latched.inv.SetBaganatorBankLive(false)
  latched:gates(prefix.."Baganator-latch-normal-release",false,false,false)
  local nativeLatch=boot(family,provider);nativeLatch:emit("BANKFRAME_OPENED")
  nativeLatch:gates(prefix.."bank-open-before-frame-PIM",true,true,false)
  nativeLatch:emit("BANKFRAME_CLOSED")
  nativeLatch:gates(prefix.."closed-before-native-ui-loaded",false,false,false)
  local b=boot(family,provider);b.inv.Builtin.Bank.SetOpen(true)
  b:gates(prefix.."builtin-open",true,true,false)
  b.inv.Builtin.Bank.SetOpen(false)
  local before=b:cached();b.inv.Builtin.Bank.Refresh()
  eq(equal(before,b:cached()),true,prefix.."actual closed Builtin.Refresh retains last-seen")
  -- Every close pattern retains access while a real visible frame or PIM owns it.
  for _,order in ipairs({"hide-close","close-hide-PIM","PIM-hide-close","native-hook-close"})do
   local q=boot(family,provider);q.bank.shown=true;q.pim[8]=true;q:emit("BANKFRAME_OPENED")
   q:gates(prefix..order.."/open",true,true,true)
   if order=="hide-close"then
    q.pim[8]=false;q:hideParent();q:emit("BANKFRAME_CLOSED");q:dueNow()
   elseif order=="close-hide-PIM"then
    q:emit("BANKFRAME_CLOSED");q:gates(prefix..order.."/early-close",true,true,true)
    q.pim[8]=false;q:hideParent();q:emit("PLAYER_INTERACTION_MANAGER_FRAME_HIDE",8);q:dueNow()
   elseif order=="PIM-hide-close"then
    q.pim[8]=false;q:emit("PLAYER_INTERACTION_MANAGER_FRAME_HIDE",8)
    q:gates(prefix..order.."/parent-still-visible",true,true,true)
    q:hideParent();q:emit("BANKFRAME_CLOSED");q:dueNow()
   else
    q.pim[8]=false;q:hideParent()
    if family=="forever"then
     eq(#(q.bank.hooks.OnHide or{}),0,prefix.."native scripts remain unhooked")
     q:emit("BANKFRAME_CLOSED")
    else q:dueNow()end
   end
   q:gates(prefix..order.."/closed",false,false,false)
   eq(q.inv.snapshots.bank.counts[1000],5,prefix..order.." last-seen five retained")
   eq(q.env._FluxUI_CharSavedVars.Bank.charCounts[1000],5,prefix..order.." persisted five retained")
  end
  -- Isolate close rechecks from the unrelated login timers in this fixture.
  local late=boot(family,provider);late.timers={}
  local closes=0
  late.inv.RegisterBankStateListener("late-close",function(open)if not open then closes=closes+1 end end)
  late.bank.shown=true;late.pim[8]=true;late:emit("BANKFRAME_OPENED")
  if provider=="builtin" then late.inv.Builtin.Bank.SetOpen(true) end
  late:emit("BANKFRAME_CLOSED");late:emit("PLAYER_INTERACTION_MANAGER_FRAME_HIDE",8)
  late:gates(prefix.."both-close-events-before-ui-settles",true,true,true)
  late:dueNow()
  late.bank.shown=false;late.pim[8]=false
  late:gates(prefix.."native-access-gone-with-no-more-events",false,false,false)
  late.now=late.now+.2;late:dueNow()
  eq(closes,1,prefix.."deferred close publishes once")
  eq(late.inv.Builtin.Bank.IsOpen(),false,prefix.."deferred close releases built-in bank snapshot owner")
  eq(late.env._FluxUI_CharSavedVars.Bank.charCounts[1000],5,prefix.."deferred close keeps cached count")
  local reopen=boot(family,provider);reopen.timers={}
  reopen.bank.shown=true;reopen:emit("BANKFRAME_OPENED");reopen:emit("BANKFRAME_CLOSED")
  reopen.bank.shown=false;reopen:emit("BANKFRAME_OPENED")
  reopen.now=reopen.now+.2;reopen:dueNow()
  reopen:gates(prefix.."fresh open cancels deferred close",true,true,false)
  local cachedClose=boot(family,provider);cachedClose.timers={}
  local cachedCloses=0
  cachedClose.inv.RegisterBankStateListener("cached-close",function(open)if not open then cachedCloses=cachedCloses+1 end end)
  cachedClose.view.shown=true;cachedClose:emit("BANKFRAME_OPENED");cachedClose:emit("BANKFRAME_CLOSED")
  cachedClose:dueNow();cachedClose.now=cachedClose.now+.2;cachedClose:dueNow()
  cachedClose:gates(prefix.."cached bank view remains accessible",true,false,true)
  cachedClose.view.shown=false;cachedClose.inv.SetBaganatorBankLive(false)
  cachedClose:gates(prefix.."cached view finally closed",false,false,false)
  eq(cachedCloses,1,prefix.."provider hide settles a previously rejected close")

  -- No close callback means the private event latch remains owned as before.
  local orphan=boot(family,provider);orphan:emit("BANKFRAME_OPENED")
  orphan:gates(prefix.."no-close-callback-latch-preserved",true,true,false)
  local wrong=boot(family,provider);wrong:emit("BANKFRAME_OPENED")
  wrong:emit("PLAYER_INTERACTION_MANAGER_FRAME_HIDE",21)
  wrong:gates(prefix.."unrelated-auction-hide-not-bank-close",true,true,false)
  -- Frame getter errors remain observable; no blanket pcall changes product semantics.
  local er=boot(family,provider);local raw={native="visibility error"};er.panel.visibleError=raw
  local ok,value=pcall(er.inv.IsBankOpen)
  eq(ok,false,prefix.."native visibility error propagates")
  eq(value,raw,prefix.."native visibility raw error preserved")
 end
end
local originalOpen,originalArg,originalGlobals=io.open,arg,_G
-- Actual consumer work: whole inventory boot plus the full restock adapter.
-- Native seams are counted desktop facts; this does not establish native FPS.
do
 local selectedInit = source or "Inventory/Init.lua"
 local fixtureFile = assert(io.open("Inventory/_tmp_inventorylag_smoke.lua", "rb"))
 local fixtureSource = fixtureFile:read("*a"); fixtureFile:close()
 local marker = assert(fixtureSource:find("-- Deferred enable can miss PEW", 1, true))
 local prefix = fixtureSource:sub(1, marker - 1)
 prefix = prefix:gsub('local root = [^\n]+', 'local root = "./"', 1)
 local fixtureIO = setmetatable({ open = function(path, mode)
  if path == "./Inventory/Init.lua" or path == "Inventory/Init.lua" then
   return io.open(selectedInit, mode)
  end
  return io.open(path, mode)
 end }, { __index = io })
 -- The borrowed fixture sees its own arg/io/global environment. The caller's
 -- arg table, io.open and globals retain their original identities.
 local fixtureEnv = setmetatable({ io = fixtureIO,
  arg = { [0] = "Inventory/_tmp_inventorylag_smoke.lua" } }, { __index = _G })
 fixtureEnv._G = fixtureEnv
 local bootInventory = assert(load(prefix .. "\nreturn boot", "@whole_inventory_boot", "t", fixtureEnv))()
 local function prepareConsumer(family, initiallyShown)
  local s = bootInventory(family, true, false)
  s.env.Enum = { BankType = { Character = 0, Account = 2 },
   BagIndex = { CharacterBankTab_1 = 100 },
   PlayerInteractionType = { Banker = 8, CharacterBanker = 67, AccountBanker = 68, Auctioneer = 21 } }
  s.flux.Cap.hasUnifiedBankUI = true
  s.flux.Cap.hasWarbandBank = false
  s.env.Syndicator.Constants.AllBankIndexes = { 100 }
  s.env.Syndicator.Constants.CharacterBankTabsActive = true
  s.char.bankTabs = { { slots = { { itemID = 1000, itemCount = 5 } } } }
  s.inv.Containers.Invalidate()
  s.childShown, s.childVisible, s.pimBanker = initiallyShown, false, false
  s.env.BankPanel = { IsShown = function() return s.childShown end,
   IsVisible = function() return s.childVisible end }
  s.env.C_PlayerInteractionManager = { IsInteractingWithNpcOfType = function(kind)
   return kind == 21 or (kind == 8 and s.pimBanker)
  end }
  s.env._FluxUI_CharSavedVars = { Bank = { charCounts = { [1000] = 5 } } }
  s.inv.snapshots.bank.counts[1000] = 5
  s.inv.snapshots.bank.byBag[100] = { { itemID = 1000, count = 5, link = "item:1000" } }
  local native = s.env.C_Container or {}
  local oldSlots, oldInfo, oldID = native.GetContainerNumSlots, native.GetContainerItemInfo, native.GetContainerItemID
  s.env.C_Container = native
  s.bankCapacityReads, s.bankInfoReads, s.bankIDReads = 0, 0, 0
  native.GetContainerNumSlots = function(bag)
   if bag == 100 then s.bankCapacityReads = s.bankCapacityReads + 1; return 32 end
   return oldSlots and oldSlots(bag) or 0
  end
  native.GetContainerItemInfo = function(bag, slot)
   if bag == 100 then s.bankInfoReads = s.bankInfoReads + 1; return nil end
   return oldInfo and oldInfo(bag, slot) or nil
  end
  native.GetContainerItemID = function(bag, slot)
   if bag == 100 then s.bankIDReads = s.bankIDReads + 1; return nil end
   return oldID and oldID(bag, slot) or nil
  end
  s.load("Inventory/Restock/FluxRestock_Inv.lua")
  s.consumerBank = s.env.FluxRestock.Inv.Bank
  function s:resetBankReads()
   self.bankCapacityReads, self.bankInfoReads, self.bankIDReads = 0, 0, 0
  end
  return s
 end
 local function preserveConsumerCounts(s, label)
  eq(s.inv.snapshots.bank.counts[1000], 5, label .. " canonical last-seen aggregate")
  eq(s.inv.snapshots.bank.byBag[100][1].count, 5, label .. " canonical last-seen row")
  eq(s.char.bankTabs[1].slots[1].itemCount, 5, label .. " provider row unchanged")
  eq(s.env._FluxUI_CharSavedVars.Bank.charCounts[1000], 5, label .. " saved last-seen count")
 end
 local function noConsumerWalk(s, label)
  eq(s.bankCapacityReads, 0, label .. " no native bank capacities")
  eq(s.bankInfoReads, 0, label .. " no native bank info walk")
  eq(s.bankIDReads, 0, label .. " no native bank ID probes")
 end
 for _, family in ipairs({ "retail", "forever", "mists", "era", "anniversary" }) do
  local label = family .. "/actual-restock/"
  -- Already hidden at adapter initialization: exercise normal passive count
  -- consumers at and beyond the unchanged 0.2s refresh throttle.
  local s = prepareConsumer(family, true)
  s:resetBankReads()
  eq(s.inv.IsBankOpen(), false, label .. " hidden child is closed")
  eq(s.inv.IsBankLive(), false, label .. " hidden child is not live")
  for i = 1, 20 do
   s.now = s.now + 0.21
   eq(s.consumerBank.GetCount(1000, { bank = true, warband = false }), 5,
    label .. " spaced getter " .. i .. " retains last-seen five")
  end
  noConsumerWalk(s, label .. "spaced")
  preserveConsumerCounts(s, label .. "spaced")
  s:resetBankReads()
  for i = 1, 20 do
   eq(s.consumerBank.GetCount(1000, { bank = true, warband = false }), 5,
    label .. " same-time getter " .. i .. " retains last-seen five")
  end
  noConsumerWalk(s, label .. "same-time")
  preserveConsumerCounts(s, label .. "same-time")
  -- Initial closed state followed by the hidden child and a real non-bank
  -- PIM event must not invoke fireOpen, its forced walk or its 0.15s rescan.
  s = prepareConsumer(family, false)
  local openCallbacks = 0
  s.consumerBank.RegisterBankOpen("visibility-regression", function() openCallbacks = openCallbacks + 1 end)
  s.childShown = true; s:resetBankReads()
  s:event("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", 21)
  s:advance(0.25)
  eq(openCallbacks, 0, label .. " Auctioneer event does not open bank")
  noConsumerWalk(s, label .. "Auctioneer")
  preserveConsumerCounts(s, label .. "Auctioneer")
  -- Positive controls keep the real adapter's walk, including its existing
  -- throttle. They reject a consumer shortcut that simply removes all scans.
  for _, access in ipairs({ "visible", "PIM" }) do
   s = prepareConsumer(family, true)
   if access == "visible" then s.childVisible = true else s.pimBanker = true end
   s:resetBankReads()
   eq(s.inv.IsBankLive(), true, label .. access .. " access remains live")
   eq(s.consumerBank.GetCount(1000, { bank = true, warband = false }), 0,
    label .. access .. " genuinely empty live result stays zero")
   eq(s.bankCapacityReads > 0, true, label .. access .. " real bank capacity queried")
   eq(s.bankInfoReads > 0, true, label .. access .. " real bank slots queried")
   local capacities, info, ids = s.bankCapacityReads, s.bankInfoReads, s.bankIDReads
   for _ = 1, 20 do s.consumerBank.GetCount(1000, { bank = true, warband = false }) end
   eq(s.bankCapacityReads, capacities, label .. access .. " same-time capacity throttle")
   eq(s.bankInfoReads, info, label .. access .. " same-time info throttle")
   eq(s.bankIDReads, ids, label .. access .. " same-time ID throttle")
   preserveConsumerCounts(s, label .. access)
  end
 end
end

do
 local h=boot("forever","syndicator")
 local e,inv=h.env,h.inv
 local prefixes={"Baganator_SingleViewBankViewFrame","Baganator_CategoryViewBankViewFrame"}
 local suffixes={"1","2","blizzard","blizzard_black","dark","elvui","gw2_ui","ndui"}
 local function view(name)
  local f={shown=false}
  function f:IsShown() return self.shown end
  e[name]=f
  return f
 end
 e.FluxBaganatorCompat=nil
 eq(inv.IsBaganatorBankViewShown(),false,"no legacy bank view is initially available")
 for _,prefix in ipairs(prefixes) do
  for _,suffix in ipairs({"","1","2","blizzard","blizzard_black","dark","elvui","gw2_ui","ndui"}) do
   local f=view(prefix..suffix)
   f.shown=true
   eq(inv.IsBaganatorBankViewShown(),true,"late named bank view "..prefix..suffix)
   f.shown=false
   eq(inv.IsBaganatorBankViewShown(),false,"visibility is read again "..prefix..suffix)
  end
 end

 local current=view(prefixes[1].."custom")
 local registered=e[prefixes[2].."dark"]
 e.Baganator={API={Skins={
  GetAllFrames=function() return {{regionType="ButtonFrame",region=registered,tags={"bank"}}} end,
  GetCurrentSkin=function() return "custom" end,
 }}}
 assert(loadfile("BaganatorCompat/FluxBaganator_BankRestock.lua","t",e))()
 local actual={}
 e.FluxBaganatorCompat.ForEachBaganatorBankView(function(f) actual[#actual+1]=f end)
 local expected={registered,current}
 for _,suffix in ipairs(suffixes) do
  for _,prefix in ipairs(prefixes) do
   local f=e[prefix..suffix]
   if f~=registered then expected[#expected+1]=f end
  end
 end
 eq(#actual,#expected,"registered, current-skin and all legacy frame count")
 for i,f in ipairs(expected) do
  eq(actual[i],f,"registered, current-skin and legacy order "..i)
 end
 current.shown=true
 eq(inv.IsBaganatorBankViewShown(),true,"current custom skin visibility is still detected")
 current.shown=false
 eq(inv.IsBaganatorBankViewShown(),false,"current custom skin visibility is read again")
end

eq(io.open,originalOpen,"consumer fixture leaves io.open identity")
eq(arg,originalArg,"consumer fixture leaves arg identity")
eq(_G,originalGlobals,"consumer fixture leaves global environment identity")
print("BANK_VISIBILITY_SCENARIOS "..scenarios)
print("BANK_VISIBILITY_CHECKS "..checks.." FAILURES "..failures)
if failures>0 then os.exit(1)end
