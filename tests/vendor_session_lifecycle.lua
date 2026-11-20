-- Actual vendor-session facade with controlled clocks, venue callbacks and errors.
-- No native UI, purchases, items or SavedVariables are touched.
local source=arg[1]or"Inventory/Restock/Vendor/FluxVendorSession.lua";local cancel=arg[2];local checks,failures,scenarios=0,0,0
local errorMarker={};local parity={}
local function cancelled()if cancel then local f=io.open(cancel,'rb');if f then f:close();error('root CANCEL',0)end end end
local function check(ok,label)checks=checks+1;if not ok then failures=failures+1;print('FAIL '..label)end end
local function eq(a,b,label)check(a==b,label..' got='..tostring(a)..' expected='..tostring(b))end
local function boot(backend)
 cancelled();local h={now=0,open=false,quiet=false,timers={},settlers={},calls={},posted=0,merchant='old',trace={},errors={}}
 local env=setmetatable({},{__index=_G});env._G=env
 local function log(kind)h.trace[#h.trace+1]=kind..'@'..string.format('%.3f',h.now)end
 local function once(key)if h[key]then local fn=h[key];h[key]=nil;return fn()end end
 local function after(dt,fn)
  h.posted=h.posted+1;log('after'..dt);once('onAfter')
  if h.afterError then error(h.afterError,0)end
  h.timers[#h.timers+1]={at=h.now+dt,fn=fn,order=h.posted}
 end
 if backend=='C_Timer'then env.C_Timer={After=after}elseif backend=='FLUX_API'then env.FLUX_API={After=after}elseif backend=='C_Timer-no-After'then env.C_Timer={};env.FLUX_API={After=after}elseif backend=='C_Timer-priority'then env.C_Timer={After=after};env.FLUX_API={After=function()error('wrong fallback selected',0)end}end
 local inv={IsMerchantOpen=function()log('open');local v=once('onOpen');if v~=nil then return v end;return h.open end,
 IsAutomationQuiet=function()log('quiet');local v=once('onQuiet');if v~=nil then return v end;return h.quiet end,
 OnQuietSettled=function(fn)log('wait');if h.settleError then error(h.settleError,0)end;h.settlers[#h.settlers+1]=fn end}
 env.FluxRestock={Inv=inv}
 local function endpoint(kind,value)
  log(kind..':'..h.merchant);h.calls[#h.calls+1]={kind=kind,merchant=h.merchant,at=h.now,value=value};once(kind=='junk'and'onJunk'or'onRestock')
  if h.uiError==kind then error(errorMarker,0)end
 end
 env.FluxVendorAutoMerchantUI={ScheduleJunkUIRefresh=function(v)endpoint('junk',v)end,ScheduleMerchantUpdate=function(v)endpoint('restock',v)end}
 assert(loadfile(source,'t',env))();h.env,h.inv,h.session,h.api=env,inv,env.FluxVendorSession,env.FluxVendorSessionRefresh
 function h:advance(t)
  while true do local best,at,order
   for i,v in ipairs(self.timers)do if v.at<=t and(not at or v.at<at or(v.at==at and v.order<order))then best,at,order=i,v.at,v.order end end
   if not best then break end;cancelled();local v=table.remove(self.timers,best);self.now=v.at;local ok,err=pcall(v.fn);if not ok then self.errors[#self.errors+1]=err end
  end;self.now=t
 end
 function h:begin(name)self.open=true;self.merchant=name or self.merchant;self.api.BeginVendorSession()end
 function h:close()self.open=false;self.api.EndVendorSession()end
 function h:request(opts)return self.api.RequestVendorRefresh(opts)end
 function h:release()local list=self.settlers;self.settlers={};for _,fn in ipairs(list)do local ok,err=pcall(fn);if not ok then self.errors[#self.errors+1]=err end end end
 function h:reopen(opts)self:close();self:begin('new');self:request(opts)end
 function h:normal(label)scenarios=scenarios+1;eq(#self.errors,0,label..' no errors');parity[#parity+1]=label..'='..table.concat(self.trace,'|')end
 return h
end
for _,backend in ipairs({'C_Timer','FLUX_API','C_Timer-no-After','C_Timer-priority'})do
 local label=backend..'/'
 local n=boot(backend);n:begin();n:request();n:request({junk=false});eq(n.posted,1,label..' active coalescing');n:advance(.149);eq(#n.calls,0,label..' retains150ms delay');n:advance(.15);eq(#n.calls,2,label..' normal whole refresh');eq(n.calls[1].value,false,label..' junk argument');eq(n.calls[2].value,'data',label..' restock argument');n:request();n:advance(.3);eq(#n.calls,4,label..' next pulse accepted');n:normal(label..'normal')
 local dup=boot(backend);dup:begin();dup:request();dup:begin();dup.session.SetOpen(true);dup:request();eq(dup.posted,1,label..' duplicate Begin/SetOpen keeps pending');dup:advance(.15);eq(#dup.calls,2,label..' duplicate Begin retains callback');dup:normal(label..'duplicateBegin')
 local direct=boot(backend);direct.inv.IsMerchantOpen=nil;direct.session.SetOpen(true);direct:request();direct.session.SetOpen(false);direct.session.SetOpen(true);direct:advance(.15);eq(#direct.calls,2,label..' direct SetOpen compatibility retained');direct:normal(label..'directSetOpen')
 local quiet=boot(backend);quiet:begin();quiet.quiet=true;quiet:request();quiet:advance(.15);eq(#quiet.settlers,1,label..' quiet wait registered once');eq(#quiet.calls,0,label..' quiet delays work');quiet:request();eq(quiet.posted,1,label..' quiet pending coalesces');quiet.quiet=false;quiet:release();eq(#quiet.calls,0,label..' quiet completion retainsAfter0 boundary');quiet:advance(.15);eq(#quiet.calls,2,label..' quiet work resumes');quiet:normal(label..'quiet')
 local live=boot(backend);live:begin();local opts={junk=false};live:request(opts);opts.junk=true;opts.restockData=false;live.env.FluxVendorAutoMerchantUI.ScheduleJunkUIRefresh=function(v)live.trace[#live.trace+1]='replacement';live.calls[#live.calls+1]={kind='replacement',value=v}end;live:advance(.15);eq(#live.calls,1,label..' options remain live');eq(live.calls[1].kind,'replacement',label..' UI callback remains live');live:normal(label..'live')
 local fallback=boot(backend);fallback:begin();fallback.env.FluxVendorAutoMerchantUI.ScheduleMerchantUpdate=nil;fallback.env.FluxVendorAutoMerchantUI.UpdateMerchantUI=function(kind)fallback.trace[#fallback.trace+1]='fallback:'..kind end;fallback:request({junk=false});fallback:advance(.15);eq(#fallback.calls,0,label..' fallback no junk');fallback:normal(label..'fallback')
 for _,which in ipairs({'after','open','quiet','junk','restock','settle','options'})do
  local err=boot(backend);err:begin();local opts
  if which=='after'then err.afterError=errorMarker elseif which=='open'then err.onOpen=function()error(errorMarker,0)end elseif which=='quiet'then err.onQuiet=function()error(errorMarker,0)end elseif which=='settle'then err.quiet=true;err.settleError=errorMarker elseif which=='options'then opts=setmetatable({},{__index=function()error(errorMarker,0)end})else err.uiError=which end
  local ok,e=pcall(function()err:request(opts)end);if not ok then err.errors[#err.errors+1]=e end;err:advance(.15);eq(#err.errors,1,label..which..' error count');check(rawequal(err.errors[1],errorMarker),label..which..' original error identity');local posts=err.posted;err:request();eq(err.posted,posts+((which=='junk'or which=='restock'or which=='options')and 1 or 0),label..which..' pending behavior inspect')
  -- Compare the precise active-session trace across baseline and candidate below.
  scenarios=scenarios+1;parity[#parity+1]=label..'error-'..which..'='..table.concat(err.trace,'|')
 end
 for _,opts in ipairs({{junk=false,restockData=false},{junk=false},{restockData=false},{}})do local h=boot(backend);h:begin();h:request(opts);h:advance(.15);local want=(opts.junk==false and 0 or 1)+(opts.restockData==false and 0 or 1);eq(#h.calls,want,label..' feature flags');h:normal(label..'flags'..want..tostring(opts.junk)..tostring(opts.restockData))end
 local closed=boot(backend);closed:begin();closed:request();closed:advance(.05);closed:close();closed:advance(.3);eq(#closed.calls,0,label..' closed callbacks inert');scenarios=scenarios+1;eq(#closed.errors,0,label..' closed no errors')
 for _,where in ipairs({'open','quiet','junk'})do
  local active=boot(backend);active:begin();local fn=function()if where=='open'then active:begin()elseif where=='quiet'then active:request()else active:request({junk=false})end end
  if where=='open'then active.onOpen=fn elseif where=='quiet'then active.onQuiet=fn else active.onJunk=fn end
  active:request();active:advance(.5);eq(#active.calls,where=='junk'and 3 or 2,label..' same-session '..where..' reentry preserved');active:normal(label..'active-reentry-'..where)
 end
 local endError=boot(backend);endError:begin();endError:request();endError:advance(.05);local setOpen=endError.session.SetOpen;endError.session.SetOpen=function(value)if not value then error(errorMarker,0)end;setOpen(value)end;endError.open=false;local ended,e=pcall(endError.api.EndVendorSession);eq(ended,false,label..' End override error propagated');check(rawequal(e,errorMarker),label..' End override error identity');endError:advance(.2);endError.session.SetOpen=setOpen;endError:begin('new');endError:request({junk=false});endError:advance(.4);eq(#endError.calls,1,label..' End override error does not strand next session');scenarios=scenarios+1
 for _,stage in ipairs({'parked','zero-queued','new-not-quiet'})do
  local edge=boot(backend);edge:begin();edge.quiet=true;edge:request();edge:advance(.15);local oldRun=edge.settlers[1];eq(type(oldRun),'function',label..stage..' original quiet waiter exists')
  if stage=='zero-queued'then oldRun()end
  local setOpen=edge.session.SetOpen;edge.session.SetOpen=function(value)if not value then error(errorMarker,0)end;setOpen(value)end;local ok,e=pcall(function()edge:close()end);check(not ok and rawequal(e,errorMarker),label..stage..' End failure identity');edge.session.SetOpen=setOpen;edge:begin('new');edge.quiet=stage~='new-not-quiet';edge:request();edge:advance(.30001)
  if stage=='new-not-quiet'then
   eq(#edge.calls,2,label..stage..' new nonquiet batch executes');oldRun();edge:request();local n=edge.posted;edge:advance(.30002);edge:request();eq(edge.posted,n,label..stage..' old quiet callback preserves new pending');edge:advance(.5);eq(#edge.calls,4,label..stage..' next new batch completes')
  else
   eq(#edge.settlers,2,label..stage..' new quiet session owns a new waiter');eq(#edge.calls,0,label..stage..' no stale UI calls');if stage=='parked'then oldRun();edge:advance(.30002)end;local n=edge.posted;edge:request();eq(edge.posted,n,label..stage..' old waiter keeps new pending');edge.quiet=false;if edge.settlers[2]then edge.settlers[2]()end;edge:advance(.30003);eq(#edge.calls,2,label..stage..' current quiet waiter completes')
  end
  eq(#edge.errors,0,label..stage..' no delayed errors');scenarios=scenarios+1
 end
 -- Intentional bug fixes: these expectations fail for baseline.
 scenarios=scenarios+1;local quick=boot(backend);quick:begin();quick:request({junk=false,restockData=true});quick:advance(.05);quick:close();quick:advance(.06);quick:begin('new');quick:request({junk=true,restockData=false});quick:advance(.151);eq(#quick.calls,0,label..' BUG old delayed callback cannot leak options');local posted=quick.posted;quick:request();eq(quick.posted,posted,label..' BUG old callback cannot clear new pending');quick:advance(.4);eq(#quick.calls,1,label..' BUG only new batch executes');eq(quick.calls[1]and quick.calls[1].kind,'junk',label..' BUG only new options')
 scenarios=scenarios+1;local parked=boot(backend);parked:begin();parked.quiet=true;parked:request({junk=false});parked:advance(.15);parked:close();parked:begin('new');parked.quiet=false;parked:request({restockData=false});parked:release();parked:advance(.151);eq(#parked.calls,0,label..' BUG old quiet callback inert before flags');posted=parked.posted;parked:request();eq(parked.posted,posted,label..' BUG old quiet callback keeps new pending');parked:advance(.4);eq(#parked.calls,1,label..' BUG old quiet options absent')
 for _,where in ipairs({'open-false','open-true','quiet-false','quiet-true','junk','after','settle'})do
  scenarios=scenarios+1;local h=boot(backend);h:begin();local hook=function()h:reopen({junk=false});if where=='open-false'or where=='quiet-false'then return false else return true end end
  if where:find('open',1,true)then h.onOpen=hook elseif where:find('quiet',1,true)then h.onQuiet=hook elseif where=='junk'then h.onJunk=hook elseif where=='settle'then h.quiet=true;h.session.OnPurchaseStormSettled=function(cb)h.quiet=false;h:reopen({junk=false});cb()end else h.onAfter=hook end
  h:request();h:advance(where=='after'and .149 or .151);local expected=where=='junk'and 1 or 0;eq(#h.calls,expected,label..' BUG '..where..' stale branch stops');posted=h.posted;h:request();eq(h.posted,posted,label..' BUG '..where..' new pending preserved');eq(#h.settlers,0,label..' BUG '..where..' old quiet callback absent');h:advance(.5);eq(#h.calls,where=='junk'and 2 or 1,label..' BUG '..where..' only current work remains');eq(#h.errors,0,label..where..' no new errors')
 end
end
local immediate=boot('none');immediate:begin();immediate:request();eq(#immediate.calls,2,'no timer backend keeps immediate behavior');immediate:normal('none/immediate')
for _,v in ipairs(parity)do print('PARITY\t'..v)end
print('R21_REGRESSION scenarios='..scenarios..' checks='..checks..' failures='..failures)
if failures>0 then os.exit(1)end
