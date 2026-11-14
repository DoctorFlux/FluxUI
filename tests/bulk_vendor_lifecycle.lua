-- Whole production BuyEmAll owner, with ordinary merchant/action APIs modeled.
local source=arg[1]or'Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua'
local baseline=arg[2]=='--baseline'
local checks,policyFailures,models=0,0,0
local function check(ok,label)checks=checks+1;assert(ok,label)end
local function policy(ok,label)
 checks=checks+1
 if not ok then policyFailures=policyFailures+1;if not baseline then error(label,2)end end
end
local function fixture()
 local s={frames={},calls={},open=true,time=0,callbacks=0,merchant='first'}
 local e=setmetatable({floor=math.floor},{__index=_G});e._G=e
 e.CreateFrame=function()
  local f={scripts={},events={}}
  function f:SetScript(key,fn)self.scripts[key]=fn end
  function f:GetScript(key)return self.scripts[key]end
  function f:RegisterEvent(key)self.events[key]=true end
  s.frames[#s.frames+1]=f;return f
 end
 e.MerchantFrame={IsShown=function()return s.open end}
 e.BuyEmAllFrame={Hide=function()s.popupHidden=true end}
 e.BuyMerchantItem=function(slot,quantity)
  s.calls[#s.calls+1]={slot=slot,quantity=quantity,at=s.time,merchant=s.merchant,closed=not s.open}
  if s.onBuy then s.onBuy(slot,quantity)end
 end
 assert(loadfile(source,'t',e))('_FluxUI',{})
 local M=e.FluxBuyEmAll;M.stack=20;M.itemIndex=7
 function s:active()
  for _,f in ipairs(self.frames)do if f.scripts.OnUpdate then return f end end
 end
 function s:step(elapsed)
  self.time=self.time+elapsed
  local f=self:active()
  if f then self.callbacks=self.callbacks+1;return f.scripts.OnUpdate(f,elapsed)end
 end
 function s:advance(seconds)
  for _=1,math.floor(seconds/.05+.5)do self:step(.05)end
 end
 function s:close()self.open=false;return M:MerchantFrame_OnHide()end
 return s,e,M
end
for _,family in ipairs({'Retail','Forever','MoP','Era','Anniversary'})do
 for _,provider in ipairs({'builtin','syndicator'})do
  models=models+1;local label=family..'/'..provider
  do
   local s,e,M=fixture();M:DoPurchase(45);s:step(.49)
   check(#s.calls==0,label..' first purchase retains half-second delay')
   s:step(.01);s:step(.5);s:step(.5)
   check(#s.calls==3 and s.calls[1].slot==7 and s.calls[2].slot==7 and s.calls[3].slot==7
    and s.calls[1].quantity==20 and s.calls[2].quantity==20 and s.calls[3].quantity==5,label..' normal full and partial stacks keep exact ordering/quantities')
   check(s.calls[1].at==.5 and s.calls[2].at==1 and s.calls[3].at==1.5,label..' normal purchase cadence unchanged')
   s:advance(1);check(not s:active(),label..' normal finite queue eventually retires')
   local values={};for _,v in ipairs(s.calls)do values[#values+1]=v.slot..':'..v.quantity..'@'..v.at end
   print('NORMAL '..label..' '..table.concat(values,','))
  end
  do
   local s,e,M=fixture();M:DoPurchase(2000);s:step(.5);s:close()
   local sent,callbacks=#s.calls,s.callbacks;s:advance(10)
   policy(#s.calls==sent and not s:active()and s.callbacks==callbacks,label..' merchant close cancels all remaining purchases and passive callbacks')
   print('WORK '..label..'/closed10s calls='..(#s.calls-sent)..',callbacks='..(s.callbacks-callbacks))
   s.open,s.merchant=true,'second';s:advance(2)
   policy(#s.calls==sent,label..' reopening another merchant cannot revive old slot purchases')
   M.itemIndex=9;M:DoPurchase(5);s:step(.5)
   check(s.calls[#s.calls].slot==9 and s.calls[#s.calls].quantity==5,label..' a distinct new press still starts fresh work after reopen')
  end
  do
   local s,e,M=fixture();s.open=false;M:DoPurchase(100);s:advance(2)
   policy(#s.calls==0 and not s:active()and s.callbacks==0,label..' an obsolete closed-context press starts no queue or callback')
  end
  do
   local s,e,M=fixture();M:DoPurchase(80);s:step(.25);s:close();s.open=true;M.itemIndex=8;M:DoPurchase(5)
   s:step(.25);policy(#s.calls==0,label..' a new request does not inherit prior elapsed time')
   s:step(.25);check(#s.calls==1 and s.calls[1].slot==8,label..' new batch starts at its own original half-second boundary')
  end
  do
   local s,e,M=fixture();M:DoPurchase(100);s:close();M:MerchantFrame_OnHide();s.open=true;s.open=true;s:advance(2)
   policy(#s.calls==0 and not s:active(),label..' duplicate close/show events cannot revive private queued work')
  end
  do
   local s,e,M=fixture();M:DoPurchase(100)
   M.OrigMerchantFrame_OnHide=function()error('original close error',0)end
   check(not pcall(s.close,s),label..' original native close callback errors still propagate')
   s:advance(2);policy(#s.calls==0 and not s:active(),label..' close cleanup precedes an original callback failure')
  end
  do
   local s,e,M=fixture();s.onBuy=function()error('permission blocked',0)end;M:DoPurchase(100)
   check(not pcall(s.step,s,.5),label..' native purchase error is never concealed')
   s.onBuy=nil;local sent=#s.calls;s:advance(2)
   policy(#s.calls==sent and not s:active(),label..' rejected native dispatch cannot leave an automatic retry loop')
  end
  do
   local s,e,M=fixture();s.onBuy=function()s:close()end;M:DoPurchase(100);s:step(.5);s.onBuy=nil;s:advance(2)
   policy(#s.calls==1 and not s:active(),label..' same-stack close cannot corrupt queue counters or retain an idle driver')
  end
  do
   local s,e,M=fixture();local once=true
   s.onBuy=function()
    if once then once=false;M.itemIndex=8;M:DoPurchase(5)end
   end
   M:DoPurchase(100);s:step(.5);s:step(.5);s:advance(1)
   policy(#s.calls==2 and s.calls[1].slot==7 and s.calls[2].slot==8 and s.calls[2].quantity==5 and not s:active(),label..' a new same-stack user request owns its own generation/counters')
  end
  do
   local s,e,M=fixture();local once=true
   e.BuyEmAllFrame.Hide=function()
    if once then once=false;M.itemIndex=9;M:DoPurchase(5)end
   end
   M:DoPurchase(100);s:step(.5);s:advance(1)
   policy(#s.calls==1 and s.calls[1].slot==9 and s.calls[1].quantity==5 and not s:active(),label..' popup reentry preserves the newest explicit request')
  end
 end
end
if not baseline then check(policyFailures==0,'all queue lifecycle policies pass')end
print('Bulk vendor lifecycle: '..checks..' checks; '..models..' shared-client/provider models; policyFailures='..policyFailures..'; native transactions NOT RUN')
