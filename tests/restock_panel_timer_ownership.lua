-- Exact production active-panel predicate, bag coalescer and count merge.
-- Native After has no return, so a fake cancellable return cannot mask defects.
local sourceRoot=arg[1]
local function read(path)local f=assert(io.open((sourceRoot and sourceRoot.."/"or"")..path,"rb"));local s=f:read("*a");f:close();return(s:gsub("\r\n","\n"))end
local text=read("AddonOptions/AceGUIWidget-FluxRestockPanel.lua")
local function part(a,b)local x=assert(text:find(a,1,true),a);local y=assert(text:find(b,x+#a,true),b);return text:sub(x,y-1)end
local attached=part("local function IsPanelAttached(widget)","local function IsPanelOpenInOptions(widget)")
local cancel=part("local function CancelPanelTimers()","local function OnPanelHiddenCleanup(")
local schedule=part("function ScheduleBagCellRefresh()","local function EnsureFrameScripts(frame)")
local merge=text:find("local function MergeCountRefreshContext(ctx)",1,true)and part("local function MergeCountRefreshContext(ctx)","local function OnRestockOptionsCountPulse(ctx)")or"local function MergeCountRefreshContext(ctx) pendingCountRefreshCtx=ctx end\n"
local checks,failures=0,0
local function check(ok,label)checks=checks+1;if not ok then failures=failures+1;print("FAIL "..label)end end
for _,client in ipairs({"live","forever","classic_era","classic_anniversary"})do
 for _,burst in ipairs({1,10,1000})do
  local s={active=true,timers={},deliveries={}}
  local e=setmetatable({},{__index=_G});e._G=e
  e.C_Timer={After=function(delay,fn)s.timers[#s.timers+1]=fn end}
  e.IsOptionsWindowOpen=function()return s.active end
  e.ShouldDeferHeavyBagCellRefresh=function()return false end
  e.FluxRestockPanel_RefreshCellData=function(ctx)s.deliveries[#s.deliveries+1]={ctx=ctx}end
  local init='local Timer=C_Timer\nlocal BAG_REFRESH_DEBOUNCE=.25\nlocal bagRefreshTimerHandle,bagRefreshTimerToken,gridRebuildTimer\nlocal pendingCountRefreshCtx,pendingCountRefreshAll\nlocal panelEngaged=true\nlocal activeWidget={frame={IsVisible=function()return true end}}\n'
  local request,stop,accumulate,replace=assert(load(init..attached..merge..cancel..schedule..'\nreturn ScheduleBagCellRefresh,CancelPanelTimers,MergeCountRefreshContext,function()activeWidget={frame={IsVisible=function()return true end}}end',"@production-restock-panel", "t",e))()
  for i=1,burst do accumulate({addedItemIDs={[i]=true},regions={bags=true}});request()end
  check(#s.timers==1,client.." one scheduled operation for burst "..burst)
  local jobs=s.timers;s.timers={};for _,fn in ipairs(jobs)do fn()end
  check(#s.deliveries==1,client.." bounded callback delivery")
  local ctx=s.deliveries[1].ctx
  check(ctx and ctx.addedItemIDs[1]and ctx.addedItemIDs[burst],client.." merged first and last dirty item")
  accumulate(nil);accumulate({removedItemIDs={[999]=true}});request()
  jobs=s.timers;s.timers={};for _,fn in ipairs(jobs)do fn()end
  check(s.deliveries[2]and s.deliveries[2].ctx==nil,client.." full refresh dominates later partial context")
  request();stop();request();jobs=s.timers;s.timers={};for _,fn in ipairs(jobs)do fn()end
  check(#s.deliveries==3,client.." hide/reopen rejects obsolete callback even for same widget")
  request();replace();jobs=s.timers;s.timers={};for _,fn in ipairs(jobs)do fn()end
  check(#s.deliveries==3,client.." replacement widget rejects old owner")
  request();s.active=false;jobs=s.timers;s.timers={};for _,fn in ipairs(jobs)do fn()end
  check(#s.deliveries==3,client.." hidden panel suppresses heavy work")
 end
end
print(("RESTOCK_TIMER checks=%d failures=%d"):format(checks,failures))
os.exit(failures>0 and 1 or 0)
