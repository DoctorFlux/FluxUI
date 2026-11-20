-- Whole production Cast/Paint/Effects error-scope regression. No business body is copied.
-- Default relative source loader; optional first argument selects an external source root.
-- Desktop models establish error/freshness/callback contracts, not native taint/FPS.
local sourceRoot = (arg and arg[1]) or "."
-- Execute complete unmodified Cast/Paint/Effects owners. No copied business body.
local checks,desiredFailures,cases=0,0,0
local function eq(a,b,label)checks=checks+1;if a~=b then error(label..' differs',0)end end
local function desired(ok,label)checks=checks+1;if not ok then desiredFailures=desiredFailures+1;print('REGRESSION '..label)end end
local function up(fn,name)
 for i=1,100 do local key,value=debug.getupvalue(fn,i);if not key then break end;if key==name then return value end end
 error('missing source upvalue '..name)
end
local function boot(family,kind,initial,sourceRoot)
 local s={input=initial,reads=0,err={label='outward-callback-error'},queue={},checkedWrites=0}
 local e=setmetatable({},{__index=_G});e._G=e
 local flux={Client={isPostDF=family=='Retail',isLiveMidnight=family=='Retail',isCamelot=family=='Forever',isAnyClassic=family~='Retail'and family~='Forever'},Bars={},Spell={},Secrets={IsSecretValue=function()return false end}}
 local ns={Flux=flux};local bars=flux.Bars
 local widget={}
 function widget:SetChecked(value)s.checkedWrites=s.checkedWrites+1;if s.failWidget then error(s.err,0)end;self.checked=value end
 local host={slot=1,column=1,widget=widget};s.host=host
 bars.ForEachHost=function(fn)fn(host)end
 bars.GetHost=function()return{main=host}end
 bars.NUM_COLUMNS=1
 flux.Action={HasAction=function()return true end}
 e.GetActionInfo=function(slot)s.reads=s.reads+1;if s.input then return'spell',s.input end end
 e.SpellIsTargeting=function()return false end
 e.UnitCastingInfo=function()end;e.UnitChannelInfo=function()end;e.GetTime=function()return 1 end
 local function load(path)local full=sourceRoot and(sourceRoot..'/'..path)or path;assert(loadfile(full,'t',e))('_FluxUI',ns)end
 load('Core/ButtonFX/Cast.lua');load('Bars/Paint.lua');load('Bars/Effects.lua')
 s.fx=flux.ButtonFX;s.paint=bars.Paint;s.effects=bars.Effects;s.flux=flux
 if kind=='lane'or kind=='dirty'then
  -- The Effects feature is optional here; the actual checked widget setter is
  -- the outward error. Both real Paint pass owners remain unchanged.
  bars.Effects=nil;s.failWidget=true
  if kind=='dirty'then
   -- A supported public UpdateDisplay callback, narrowed to the real checked
   -- paint so the dirty pass reaches the identical native-widget boundary.
   bars.Paint.UpdateDisplay=function(h)bars.Paint.UpdateChecked(h)end
  end
 else
  s.fx.Glow={Want=function(id)s.wanted=id;error(s.err,0)end}
  if kind=='effects-deferred'then flux.Timer={Defer=function(fn)s.queue[#s.queue+1]=fn end}end
 end
 function s.active()return up(s.fx.SpellIdFromAction,'memoActive')end
 function s.run()
  if kind=='lane'then return s.paint.Flush({['bars.checked']=true})
  elseif kind=='dirty'then s.paint.MarkDirty(host);return s.paint.Flush({['bars.dirty']=true})
  elseif kind=='effects-deferred'then
   s.effects.Refresh(host);eq(s.active(),false,'deferred refresh does not start pass early');eq(#s.queue,1,'one unchanged defer');return s.queue[1]()
  else return s.effects.Refresh(host)end
 end
 return s
end

if FLUX_SLOT_PASS_FIXTURE_EXPORT then return boot end
local function new(family,kind,initial)
 local s=boot(family,kind,initial,sourceRoot)
 local begin,finish=s.fx.BeginSlotPass,s.fx.EndSlotPass
 s.trace={}
 s.fx.BeginSlotPass=function(...)s.trace[#s.trace+1]='begin';return begin(...)end
 s.fx.EndSlotPass=function(...)s.trace[#s.trace+1]='end';return finish(...)end
 return s
end
local function pack(...)return{n=select('#',...),...}end
do
 for _,family in ipairs({'Retail','Forever','MoP','Era','Anniversary'})do
  for _,kind in ipairs({'lane','dirty','effects-immediate','effects-deferred'})do
   cases=cases+1;local s=new(family,kind,101)
   local ok,err=pcall(s.run);eq(ok,false,'outward error');eq(err,s.err,'opaque error identity');eq(table.concat(s.trace,','),'begin','original error callback trace retained')
   eq(s.reads,1,'one cached native read before error');s.input=202
   desired(s.active()==false,family..'/'..kind..' closes aborted pass')
   desired(s.fx.SpellIdFromAction(1)==202,family..'/'..kind..' outside query fresh')
   s.fx.EndSlotPass();eq(s.fx.SpellIdFromAction(1),202,'existing explicit close remains compatible')
  end
  for _,kind in ipairs({'lane','dirty','effects-immediate','effects-deferred'})do
   cases=cases+1;local s=new(family,kind,101);s.failWidget=false
   if kind:find('effects',1,true)then s.fx.Glow.Want=function(id)s.wanted=id;return false end end
   local values=pack(s.run());eq(values.n,0,'unchanged zero-result public flow')
   eq(s.active(),false,'normal pass inactive');eq(table.concat(s.trace,','),'begin,end','normal callbacks exact')
   eq(s.reads,1,'normal native action reads exact');eq(s.checkedWrites,1,'normal checked write exact')
   s.input=202;eq(s.fx.SpellIdFromAction(1),202,'normal outside fresh')
   print('NORMAL '..family..'/'..kind..' callbacks=begin,end nativeReads=1 widgetWrites=1 defers='..#s.queue)
  end
 end
 cases=cases+1
 do local s=new('Forever','lane',nil);local ok,err=pcall(s.run);eq(ok,false,'initial nil error');eq(err,s.err,'initial nil raw error');s.input=202;eq(s.fx.SpellIdFromAction(1),202,'first positive fresh');s.input=303;desired(s.fx.SpellIdFromAction(1)==303,'initial nil error cannot capture later outside positive');desired(s.active()==false,'initial nil error closes active flag')end
 local probe = new('Forever','lane',101)
 if type(probe.fx.WithSlotPassCleanup)=='function'then
  local s=probe;local guard=s.fx.WithSlotPassCleanup;local touches=0
  local opaque=setmetatable({},{__tostring=function()touches=touches+1;error('touched')end})
  for _,n in ipairs({0,1,2,3,6})do
   cases=cases+1;local t={n=n,[1]=false,[3]='tail',[6]=11};local r=pack(guard(function(...)return table.unpack(t,1,t.n)end,7,nil,8,nil));eq(r.n,n,'guard preserves arity');for i=1,n do eq(r[i],t[i],'guard return hole')end
  end
  cases=cases+1;s.fx.BeginSlotPass();eq(s.fx.SpellIdFromAction(1),101,'outer cached');local ok,err=pcall(guard,function()error(opaque,0)end);eq(ok,false,'early error');eq(err,opaque,'opaque same');eq(s.active(),true,'early error preserves existing outer pass');s.input=202;eq(s.fx.SpellIdFromAction(1),101,'outer answer unchanged');s.fx.EndSlotPass();eq(s.fx.SpellIdFromAction(1),202,'outer explicit end fresh');eq(touches,0,'opaque uninspected')
  cases=cases+1;s.input=303;ok,err=pcall(guard,function()s.fx.BeginSlotPass();s.fx.SpellIdFromAction(1);error(opaque,0)end);eq(ok,false,'begun error');eq(err,opaque,'same begun error');eq(s.active(),false,'begun failure closes');s.input=404;eq(s.fx.SpellIdFromAction(1),404,'post failure fresh')
  cases=cases+1;s.input=101;guard(function()s.fx.BeginSlotPass();eq(s.fx.SpellIdFromAction(1),101,'nested outer');guard(function()s.fx.BeginSlotPass();s.input=202;eq(s.fx.SpellIdFromAction(1),202,'nested inner');s.fx.EndSlotPass()end);s.input=303;eq(s.fx.SpellIdFromAction(1),303,'existing nested End still disables outer memo');s.fx.EndSlotPass()end);eq(s.active(),false,'nested complete')
  cases=cases+1;s.input=101;local prior=s.fx.BeginSlotPass;s.fx.BeginSlotPass=function()prior();s.fx.SpellIdFromAction(1);error(opaque,0)end;ok,err=pcall(s.run);eq(ok,false,'public Begin hook throws');eq(err,opaque,'Begin raw identity');eq(s.active(),false,'Begin hook cleans');s.fx.BeginSlotPass=prior
  cases=cases+1;s.input=101;s.failWidget=false;local priorEnd=s.fx.EndSlotPass;s.fx.EndSlotPass=function()error(opaque,0)end;ok,err=pcall(s.run);eq(ok,false,'public End hook throws');eq(err,opaque,'End raw identity');eq(s.active(),false,'End hook cleanup');s.fx.EndSlotPass=priorEnd
  cases=cases+1;s.input=101;s.failWidget=true;s.paint.ClearCache(s.host);s.fx.EndSlotPass=function()error('secondary must not run',0)end;ok,err=pcall(s.run);eq(ok,false,'body error');eq(err,s.err,'primary error not replaced');eq(s.active(),false,'primary cleanup private')
  cases=cases+1;s.fx.EndSlotPass=priorEnd;s.input=101;s.fx.BeginSlotPass();s.fx.SpellIdFromAction(1);local missing=setmetatable({},{__index=function()error(opaque,0)end});ok,err=pcall(s.paint.Flush,missing);eq(ok,false,'error before Begin');eq(err,opaque,'same token error');eq(s.active(),true,'outside outer pass preserved');s.fx.EndSlotPass()
  cases=cases+1;local noOp=function()end;for i=1,100 do guard(noOp)end;collectgarbage('collect');collectgarbage('stop');local before=collectgarbage('count');for i=1,10000 do guard(noOp)end;local amount=collectgarbage('count')-before;collectgarbage('restart');if amount>2 then error('guard adds linear per-call heap',0)end;print('GUARD_ALLOCATION_KiB_10000 '..amount)
 end
 print(('Slot-pass lifecycle: %d cases/%d checks, %d freshness regressions'):format(cases,checks,desiredFailures));assert(desiredFailures==0,'aborted paint pass leaked stale slot identity')
end
