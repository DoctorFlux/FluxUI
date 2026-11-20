
-- Whole production Era/Anniversary bag owner; native/frame visibility and paint sinks modeled.
-- Optional owner-path arg supports external baseline replay. No client, item or preference actions.
local selected=arg[1]or'Inventory/Builtin/FluxClassicCombinedBag.lua'
local Model=assert(loadfile('tests/support/classic_combined_bag_model.txt'))()
local function boot(family,extra)
 local config={family=family,bags=5,slots=16,knownCallbacks=true}
 for k,v in pairs(extra or{})do config[k]=v end;config.source=selected;return Model(config)
end
local checks,cases,failures=0,0,{}
local function eq(a,b,label)checks=checks+1;if a~=b then error(label..' differs',0)end end
local function run(name,fn)
 cases=cases+1;local ok,err=pcall(fn)
 if not ok then local message=type(err)=='string'and err or('opaque '..type(err));failures[#failures+1]=name..': '..message;print('FAIL '..failures[#failures])end
end
local function native(s,id)for _,f in ipairs(s.native)do if f:GetID()==id then return f end end end
local function returnBody(s)for fn,name in pairs(s.functions)do if name=='ReturnItems'then return fn end end;error('missing actual ReturnItems')end
local function count(s,name)return s.metrics[name..':entered']or 0 end
for _,family in ipairs({'era','anniversary'})do
 run(family..'/ordinary-open-and-repair',function()
  local s=boot(family);local ok=s:withCounts(s.e.ToggleAllBags);eq(ok,true,'whole owner opens');eq(#s.combined.FluxHostedButtons,80,'all80 native items adopted')
  eq(count(s,'Refresh'),12,'unchanged current full Refresh cadence');eq(count(s,'HostFor'),640,'unchanged actual adoption work')
  local reads=0
  for _,b in ipairs(s.combined.FluxHostedButtons)do local h=b:GetParent();local original=h.IsShown;h.IsShown=function(self)reads=reads+1;return original(self)end;eq(b:GetScript('OnClick'),s.itemHandlers[b],'native item handler retained')end
  local before=count(s,'LayoutItems');s:withCounts(s.event,s,'BAG_UPDATE',0)
  eq(reads,0,'normal correct-parent repin adds no host visibility API reads');eq(count(s,'LayoutItems'),before,'unchanged capacity has no extra layout')
  local b=s.combined.FluxHostedButtons[1];local host=b:GetParent();b:SetParent(host.fluxContainer);s:withCounts(s.event,s,'BAG_UPDATE',0);eq(b:GetParent(),host,'genuine used-host displacement repaired')
  local hidden=s.e.CreateFrame('Frame',nil,s.e.UIParent);hidden:Hide();host:SetParent(hidden);b:SetParent(host.fluxContainer);s:withCounts(s.event,s,'BAG_UPDATE',0)
  eq(b:GetParent(),host,'local shown host repaired under foreign hidden parent');host:SetParent(s.combined)
  eq(#s.junk,5,'known native-update junk callback delivery retained')
  local money=native(s,0).MoneyFrame;eq(s.parentLabel(money),'gold-strip','money remains in combined strip');eq(#money.hookLists.OnEnter,1,'ledger attachment idempotent')
  s.rawEmit(money,'OnEnter');eq(s.tooltip,1,'real ledger callback runs');eq(s.tooltipParent,'gold-strip','ledger current anchor retained')
 end)
 run(family..'/specialty-release-and-return',function()
  local s=boot(family);s:withCounts(s.e.ToggleAllBags);local f=native(s,2);local items={};for i=1,f.size do items[i]=s.objects[f:GetName()..'Item'..i]end
  s.cfg.specialty={[2]=true};s:withCounts(s.event,s,'PLAYER_EQUIPMENT_CHANGED');eq(#s.combined.FluxHostedButtons,64,'specialty omitted from ordinary list');eq(f:GetAlpha(),1,'specialty native alpha restored')
  for _,b in ipairs(items)do eq(b:GetParent(),f,'released specialty native parent retained');eq(b:IsVisible(),true,'specialty item visible');eq(b:GetScript('OnClick'),s.itemHandlers[b],'specialty handler retained')end
  s.cfg.specialty={};s:withCounts(s.event,s,'PLAYER_EQUIPMENT_CHANGED');eq(#s.combined.FluxHostedButtons,80,'ordinary bag returns to list')
  for _,b in ipairs(items)do eq(b:GetParent().fluxContainer,f,'same button returns to ordinary host');eq(b:GetParent():GetID(),2,'same logical bag ID');eq(b:IsVisible(),true,'ordinary item visible')end
 end)
 run(family..'/remove-and-equip',function()
  local s=boot(family);s:withCounts(s.e.ToggleAllBags);local f=native(s,3)
  s.cfg.sizes={[3]=0};s.e.CloseBag(3);s:withCounts(s.event,s,'BAG_UPDATE',3);eq(#s.combined.FluxHostedButtons,64,'removed bag omitted')
  s.cfg.sizes[3]=16;s:withCounts(s.e.OpenBag,3);eq(#s.combined.FluxHostedButtons,80,'same native frame reopened on equip')
  eq(native(s,3),f,'native frame reused')
 end)
 run(family..'/reused-bank-frame-repin',function()
  local s=boot(family);s:withCounts(s.e.ToggleAllBags);s:withCounts(s.e.CloseAllBags);s.cfg.externalSizes={[5]=16};s:withCounts(s.e.OpenBag,5)
  local bank=native(s,5);s:withCounts(s.e.ToggleAllBags);s:withCounts(s.event,s,'BAG_UPDATE',0)
  for i=1,bank.size do local b=s.objects[bank:GetName()..'Item'..i];eq(b:GetParent(),bank,'inactive historical host does not steal reused bank item');eq(b:GetScript('OnClick'),s.itemHandlers[b],'reused handler retained')end
 end)
 run(family..'/reused-foreign-owner-close',function()
  local s=boot(family);s:withCounts(s.e.ToggleAllBags);s:withCounts(s.e.CloseAllBags);s.cfg.externalSizes={[5]=16};s:withCounts(s.e.OpenBag,5)
  local bank=native(s,5);s:withCounts(s.e.ToggleAllBags)
  local foreign=s.e.CreateFrame('Frame',nil,s.e.UIParent);foreign:SetID(5)
  for i=1,bank.size do local b=s.objects[bank:GetName()..'Item'..i];b:SetParent(foreign);b:ClearAllPoints();b:SetPoint('foreign-point',foreign)end
  s:withCounts(s.e.CloseAllBags);eq(bank:IsShown(),true,'bank session remains open')
  for i=1,bank.size do local b=s.objects[bank:GetName()..'Item'..i];eq(b:GetParent(),foreign,'close preserves another current owner');eq(b:GetNumPoints(),1,'foreign geometry untouched')end
 end)
 run(family..'/late-alternative-handoff',function()
  local s=boot(family);s:withCounts(s.e.ToggleAllBags)
  local b=s.combined.FluxHostedButtons[1];local other=s.e.CreateFrame('Frame',nil,s.e.UIParent);b:SetParent(other);b:ClearAllPoints();b:SetPoint('alternative-point',other)
  s.cfg.alternative=true;s:withCounts(s.event,s,'ADDON_LOADED','Baganator')
  eq(s.combined:IsShown(),false,'late Baganator closes custom UI');eq(b:GetParent(),other,'handoff preserves already adopted external item');eq(b:GetNumPoints(),1,'handoff preserves external point')
  local before=count(s,'Refresh');s:withCounts(s.e.OpenAllBags);eq(count(s,'Refresh'),before,'alternative owner bypasses own layout')
 end)
 run(family..'/return-api-and-hidden-cleanup',function()
  local s=boot(family);s:withCounts(s.e.ToggleAllBags);local list=s.combined.FluxHostedButtons;local own,already,foreign,hidden=list[1],list[2],list[3],list[4]
  local body=returnBody(s);local other=s.e.CreateFrame('Frame',nil,s.e.UIParent)
  already:SetParent(already:GetParent().fluxContainer);already:ClearAllPoints();already:SetPoint('native-point',s.e.UIParent)
  foreign:SetParent(other);foreign:ClearAllPoints();foreign:SetPoint('foreign-point',other);hidden:GetParent():Hide()
  local calls={}
  for tag,b in pairs({own=own,already=already,foreign=foreign,hidden=hidden})do
   local data={GetParent=0,SetParent=0,ClearAllPoints=0};calls[tag]=data
   for _,name in ipairs({'GetParent','SetParent','ClearAllPoints'})do local previous=b[name];b[name]=function(self,...)
    if debug.getinfo(2,'f').func==body then data[name]=data[name]+1 end;return previous(self,...)
   end end
  end
  local ok=s:withCounts(body);eq(ok,true,'actual cleanup completes')
  for _,tag in ipairs({'own','already','foreign','hidden'})do eq(calls[tag].GetParent<=1,true,'cleanup retains parent-read bound '..tag)end
  for _,tag in ipairs({'own','hidden'})do eq(calls[tag].SetParent,1,'visible/hidden owned parent restored '..tag);eq(calls[tag].ClearAllPoints,1,'visible/hidden owned points cleared '..tag)end
  for _,tag in ipairs({'already','foreign'})do eq(calls[tag].SetParent,0,'unowned parent untouched '..tag);eq(calls[tag].ClearAllPoints,0,'unowned points untouched '..tag)end
  eq(already:GetNumPoints(),1,'native geometry retained');eq(foreign:GetNumPoints(),1,'foreign geometry retained');eq(foreign:GetParent(),other,'current foreign parent retained')
 end)
 run(family..'/raw-parent-error',function()
  local s=boot(family,{bags=1,slots=1});s:withCounts(s.e.ToggleAllBags);local b=s.combined.FluxHostedButtons[1];local marker={}
  b.GetParent=function()error(marker,0)end
  local ok,err=s:withCounts(returnBody(s));eq(ok,false,'original parent failure propagates');eq(err,marker,'raw error object retained')
 end)
 run(family..'/raw-native-open-partial',function()
  for _,after in ipairs({false,true})do
   local marker={};local config={errorObject=marker};if after then config.errorAfterShow=2 else config.errorAtBag=2 end
   local s=boot(family,config);local ok,err=s:withCounts(s.e.ToggleAllBags)
   eq(ok,false,'native open failure propagates');eq(err,marker,'native raw identity retained');eq(s.combined:IsShown(),false,'partial open remains unshown')
   eq(#s.combined.FluxHostedButtons,after and 48 or 32,'existing partial hosted state retained');eq(count(s,'Refresh'),after and 5 or 4,'existing partial callbacks retained')
  end
 end)
end
print(('Classic combined bag ownership: %d cases / %d checks / %d failures; desktop models, native FPS/taint/pixels NOT RUN'):format(cases,checks,#failures))
if#failures>0 then os.exit(1)end
