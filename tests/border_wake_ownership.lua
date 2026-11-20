-- Deterministic standalone clock/After/scheduler model running the actual Core.
-- No client/process/window/settings/native access or CPU measurement.
table.unpack=table.unpack or unpack
if _VERSION=='Lua 5.1' then local prior=load;load=function(s,n,m,e)if type(s)~='string'then return prior(s,n)end;local f,x=loadstring(s,n);if f and e then setfenv(f,e)end;return f,x end end
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s:gsub('\r\n','\n')end
local path,expect,fixturePath=arg[1]or'Core/BorderJunctions.lua',arg[2]or'candidate',arg[3]or'tests/border_junctions.lua'
local source=read(path);local prefix=assert(read(fixturePath):match('^(.-)local J=fixture%(%)'))
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function json(v)
 local t=type(v)
 if t=='string'then return '"'..v:gsub('[%z\1-\31\\"]',function(c)local map={['\\']='\\\\',['"']='\\"',['\n']='\\n',['\r']='\\r',['\t']='\\t'};return map[c]or string.format('\\u%04x',c:byte())end)..'"'end
 if t=='number'then return string.format('%.17g',v)end
 if t=='boolean'then return tostring(v)end
 if t=='nil'then return'null'end
 local array=true;local n=0;for k in pairs(v)do if type(k)~='number'then array=false;break end;n=math.max(n,k)end
 local out={};if array then for i=1,n do out[#out+1]=json(v[i])end;return'['..table.concat(out,',')..']'end
 local keys={};for k in pairs(v)do keys[#keys+1]=k end;table.sort(keys);for _,k in ipairs(keys)do out[#out+1]=json(k)..':'..json(v[k])end;return'{'..table.concat(out,',')..'}'
end
local export='\nreturn {state=function() return dirty,queued,nextPass,ready end,setReady=function(v)ready=v end,phase=function()return rectReadPhase end}\n'
local text,n=prefix:gsub('read%("Core/BorderJunctions.lua"%)',function()return string.format('%q',source..export)end);assert(n==1)
text,n=text:gsub('    assert%(load%(', '    e.inspect=assert(load(',1);assert(n==1)
local baseFixture=assert(load(text..'\nreturn fixture','@external-wake-fixture','t',_G))()
local function fixture(style,options)
 options=options or{}
 local j,new,piece,_,objects,locked,choose,_,e=baseFixture(true);choose(style or 1,'class')
 local c={time=0,tasks={},nextID=0,scheduled={},fired={},entries={},queries={},passRows={},errors={},getTimeCalls=0,schedulerCalls=0,afterCalls=0,logging=true}
 local ids={};for i,o in ipairs(objects)do ids[o]=i end
 local function id(o)if not ids[o]then for i,value in ipairs(objects)do if rawequal(value,o)then ids[o]=i;break end end end;return ids[o]or 0 end
 -- Object-keyed weak tables have no cross-instance iteration order guarantee.
 -- Canonicalize modeled native-object and scalar map keys, whose ordinary
 -- pairs order is unspecified, so exact query order is reproducible. Unknown
 -- local table identities retain normal traversal and are never serialized.
 e.pairs=function(t)
  local keys={}
  for key in pairs(t)do if type(key)=='table'and id(key)==0 then return pairs(t)end;keys[#keys+1]=key end
  table.sort(keys,function(a,b)local ta,tb=type(a),type(b);if ta~=tb then return ta<tb elseif ta=='table'then return id(a)<id(b)elseif ta=='boolean'then return not a and b else return a<b end end)
  local index=0;return function()index=index+1;local key=keys[index];if key~=nil then return key,t[key]end end
 end
 local m=getmetatable(e.UIParent).__index
 for key,fn in pairs(m)do if type(fn)=='function'and(key:match('^Get')or key:match('^Is'))then local native,name=fn,key;m[key]=function(self,...)if c.logging then c.queries[#c.queries+1]=string.format('%.6f|%s|%d',c.time,name,id(self))end;return native(self,...)end end end
 local actualFlush=j.Flush
 function j:Flush(...)c.entries[#c.entries+1]={time=c.time,dirty=e.inspect.state()};return actualFlush(self,...)end
 function c:state()local d,q,np,r=e.inspect.state();return{dirty=d,queued=q,nextPass=np,ready=r}end
 function c:enqueue(kind,delay,fn)
  self.nextID=self.nextID+1;local t={id=self.nextID,kind=kind,due=self.time+delay,fn=fn};self.tasks[#self.tasks+1]=t
  self.scheduled[#self.scheduled+1]={id=t.id,kind=kind,due=t.due,at=self.time,delay=delay};return t.id
 end
 e.GetTime=function()c.getTimeCalls=c.getTimeCalls+1;if c.clockError then c.clockError=false;error('modeled clock failure',0)end;return c.time end
 if options.noClock then e.GetTime=false end
 e.C_Timer={After=function(delay,fn)
  c.afterCalls=c.afterCalls+1
  if c.afterError then c.afterError=false;error('modeled timer registration failure',0)end
  local id=c:enqueue('timer',delay,fn)
  if c.afterHook then local hook=c.afterHook;c.afterHook=nil;hook()end
  return id
 end}
 if options.noTimer then e.C_Timer=false end
 e.Flux.Scheduler={Request=function(tier,token,fn)
  check(tier=='structural'and token=='border.junctions','border retains shared structural routing')
  c.schedulerCalls=c.schedulerCalls+1
  if c.schedulerError then c.schedulerError=false;error('modeled scheduler registration failure',0)end
  c:enqueue('scheduler',0,fn)
 end}
 if options.noScheduler then e.Flux.Scheduler=false end
 function c:runAt(t)
  self.time=t;local count=0
  while true do
   local index
   for i,task in ipairs(self.tasks)do if task.due<=t+1e-12 and(not index or task.due<self.tasks[index].due or task.due==self.tasks[index].due and task.id<self.tasks[index].id)then index=i end end
   if not index then break end
   count=count+1;check(count<100,'bounded deterministic callback drain')
   local task=table.remove(self.tasks,index);self.fired[#self.fired+1]={id=task.id,kind=task.kind,time=t,due=task.due}
   local before=j.stats.passes;local ok,err=pcall(task.fn);if not ok then self.errors[#self.errors+1]=tostring(err);error(err,0)end
   if j.stats.passes~=before then self.passRows[#self.passRows+1]={time=t,passes=j.stats.passes,reads=j.stats.geometryReads,solves=j.stats.solves}end
  end
 end
 function c:fireKind(kind,t)
  self.time=t
  for i,task in ipairs(self.tasks)do if task.kind==kind and task.due<=t+1e-12 then table.remove(self.tasks,i);self.fired[#self.fired+1]={id=task.id,kind=task.kind,time=t,due=task.due};task.fn();return true end end
  return false
 end
 function c:world()
  local listeners={};for _,o in ipairs(objects)do if o.OnEvent then listeners[#listeners+1]=o end end
  for _,o in ipairs(listeners)do o:OnEvent('PLAYER_ENTERING_WORLD')end
 end
 function c:regen()for _,o in ipairs(objects)do if o.OnEvent then o:OnEvent('PLAYER_REGEN_ENABLED')end end end
 local root=new(e.UIParent,{0,0,100,100});local h=piece(root,'Top',{0,-9,100,17});local v=piece(root,'Left',{41,-40,16,80})
 for _,p in ipairs{h,v}do local get=p.GetRect;function p:GetRect()local x,y,w,hh=get(self);return x+root.rect[1],y+root.rect[2],w,hh end end
 function c:move()root.rect[1]=root.rect[1]+3;j:Invalidate(nil,root)end
 function c:warm()self:world();self:runAt(0);if options.noScheduler and options.noTimer then j:CommitLayout()end;check(j.stats.solves==1,'fixture completes one actual warm solve')end
 function c:mesh()
  self.logging=false;local out={}
  for _,t in ipairs(objects)do if t.decorative and t:IsShown()and t:GetAlpha()>0 and t.size and t.point then
   local parent=t:GetParent();local p=t.point;local values={parent:GetLeft()+(p[4]or 0),parent:GetBottom()+(p[5]or 0),t.size[1],t.size[2],t:GetAlpha()}
   for _,value in ipairs(t.uv)do values[#values+1]=value end
   for k=1,4 do local vv=t.vertices and t.vertices[k]or{0,0};values[#values+1]=vv[1];values[#values+1]=vv[2]end
   local r,g,b=t:GetVertexColor();values[#values+1]=r;values[#values+1]=g;values[#values+1]=b;values[#values+1]=parent:GetFrameLevel()
   for i,value in ipairs(values)do values[i]=string.format('%.17g',value)end
   values[#values+1]=t.path;values[#values+1]=parent:GetFrameStrata();values[#values+1]=t.layer or'ARTWORK';values[#values+1]=t.sublevel or 0;out[#out+1]=table.concat(values,',')
  end end
  table.sort(out);self.logging=true;return table.concat(out,'\n')
 end
 function c:record(name)return{name=name,errors=self.errors,entries=self.entries,scheduled=self.scheduled,fired=self.fired,passes=j.stats.passes,reads=j.stats.geometryReads,solves=j.stats.solves,full=j.stats.fullInvalidations,mesh=self:mesh(),queries=table.concat(self.queries,'\n'),state=self:state(),schedulerCalls=self.schedulerCalls,afterCalls=self.afterCalls,getTimeCalls=self.getTimeCalls}end
 c.j,c.root,c.h,c.v,c.e,c.locked,c.objects=j,root,h,v,e,locked,objects
 return c
end
local records={}
for _,style in ipairs{1,2}do
 -- Producers before world entry retain dirtiness without scheduling work.
 local cold=fixture(style);cold.time=.01;cold:move();cold.j:CommitLayout();cold.j:Flush()
 check(cold.j.stats.passes==0 and #cold.tasks==0 and cold:state().dirty,'not-ready producers and explicit commits remain deferred')
 cold:world();cold:runAt(.01);check(cold.j.stats.solves==1,'world entry resumes the existing cold dirty state')
 records[#records+1]=cold:record('initial-readiness-'..style)
 -- An explicit commit consumes old delayed work; a new burst has its own wake.
 local c=fixture(style);c:warm();c.time=.01;c:move();c:runAt(.01)
 c.time=.02;c.j:CommitLayout();c.time=.03;c:move();c:runAt(.03)
 local entries=#c.entries;c:runAt(.05);local stale=#c.entries-entries;c:runAt(.07)
 check(c.j.stats.passes==3 and c.j.stats.solves==3,'explicit commit and current deadline each consume actual changed geometry once')
 if expect=='baseline'then check(stale==1 and c.afterCalls==3,'baseline reproduces old callback rearming an already owned deadline')else check(stale==0 and c.afterCalls==2,'stale delayed callback cannot enter Flush or multiply the current delayed wake')end
 records[#records+1]=c:record('commit-stale-'..style)
 -- Every replacement retains the original earliest rate-limit deadline.
 c=fixture(style);c:warm();c.time=.01;c:move();c:runAt(.01)
 for _,t in ipairs{.02,.03,.04}do c.time=t;c.j:Flush()end
 c:runAt(.049);check(c.j.stats.solves==1,'manual deferrals never build before the existing deadline')
 c:runAt(.05);check(c.j.stats.solves==2 and not c:state().dirty,'latest replacement still consumes work at the original earliest deadline')
 records[#records+1]=c:record('same-deadline-'..style)
 -- A stale callback must not clear the queue owner while another delay waits.
 c=fixture(style);c:warm();c.time=.01;c:move();c:runAt(.01);c.time=.02;c.j:CommitLayout();c.time=.03;c:move();c:runAt(.03);c.locked(true);c:runAt(.05)
 local q=c:state().queued
 if expect=='baseline'then check(not q,'baseline stale locked callback clears the current queued flag')else check(q,'stale locked callback preserves the current queued flag')end
 c.time=.051;c.locked(false);local calls=c.schedulerCalls;c:move()
 if expect=='baseline'then check(c.schedulerCalls==calls+1,'baseline stale callback permits an unnecessary structural request')else check(c.schedulerCalls==calls,'candidate retains the current wake without a duplicate structural request')end
 c:runAt(.051);c:runAt(.07);check(c.j.stats.solves==3,'locked stale wake retains actual subsequent geometry')
 records[#records+1]=c:record('locked-stale-'..style)
 -- A manual early Flush must leave the sole useful already registered wake live.
 for _,mode in ipairs{'locked','not-ready'}do
  c=fixture(style);c:warm();c.time=.01;c:move();c:runAt(.01);c.time=.02
  if mode=='locked'then c.locked(true)else c.e.inspect.setReady(false)end
  c.j:Flush();check(c:state().dirty,'early manual Flush retains dirty work')
  if mode=='locked'then c.locked(false)else c.e.inspect.setReady(true)end
  c:runAt(.05);check(c.j.stats.solves==2,'sole pending wake recovers after '..mode..' early return without new invalidation/event')
  records[#records+1]=c:record('early-'..mode..'-'..style)
 end
 -- A fresh ordinary scheduler request does not supersede a useful old timer
 -- while the shared bus is still pending. Test that timer independently first.
 c=fixture(style);c:warm();c.time=.01;c:move();c:runAt(.01);c.time=.02;c.locked(true);c.j:Flush();c.locked(false);c.time=.03;c:move()
 check(c:fireKind('timer',.05)and c.j.stats.solves==2,'old useful timer retains the earliest deadline while a new shared-bus callback is pending')
 c:runAt(.06);check(c.j.stats.solves==2 and not c:state().dirty,'later shared-bus callback cannot replay the consumed pending geometry')
 records[#records+1]=c:record('useful-before-bus-'..style)
 -- Errors arming a replacement cannot invalidate a useful prior timer.
 for _,mode in ipairs{'timer','clock','scheduler'}do
  c=fixture(style);c:warm();c.time=.01;c:move();c:runAt(.01);c.time=.02
  local ok,err
  if mode=='timer'then c.afterError=true;ok,err=pcall(function()c.j:Flush()end)
  elseif mode=='clock'then c.clockError=true;ok,err=pcall(function()c.j:Flush()end)
  else c.locked(true);c.j:Flush();c.locked(false);c.schedulerError=true;ok,err=pcall(function()c:move()end)end
  check(not ok and tostring(err)=='modeled '..(mode=='timer'and'timer registration'or mode=='scheduler'and'scheduler registration'or'clock')..' failure','exact '..mode..' error is surfaced')
  c:runAt(.05);check(c.j.stats.solves==2,'useful old wake survives '..mode..' failure')
  records[#records+1]=c:record('failure-'..mode..'-'..style)
 end
 -- Artificial registration reentry checks publication atomicity; normal After
 -- is asynchronous. The model's nested explicit commit remains authoritative.
 c=fixture(style);c:warm();c.time=.01;c:move();c.afterHook=function()c.j:CommitLayout()end;c:runAt(.01)
 local count=#c.entries;c:runAt(.05)
 if expect~='baseline'then check(#c.entries==count,'registration reentry cannot republish a consumed reservation')end
 check(c.j.stats.solves==2,'nested explicit commit is retained')
 records[#records+1]=c:record('registration-reentry-'..style)
 -- Native getter invalidation schedules fresh work after the currently consumed
 -- pass. All current rectangles/material reads stay in the actual renderer.
 c=fixture(style);c:warm();local get=c.h.GetRect;local once=true
 function c.h:GetRect()if once then once=false;c.j:Invalidate(true)end;return get(self)end
 c.time=.06;c:move();c:runAt(.06);c:runAt(.11)
 check(c.j.stats.passes==3 and c.j.stats.geometryReads==3 and c.j.stats.solves==2 and not c:state().dirty,'native getter reentrant invalidation receives its own fresh read pass and unchanged-signature skip')
 records[#records+1]=c:record('getter-reentry-'..style)
 -- Combat stops the rate-limited callback; repeated regen wakes still coalesce.
 c=fixture(style);c:warm();c.time=.01;c:move();c:runAt(.01);c.locked(true);c:runAt(.05);check(c:state().dirty,'combat-held callback retains work');c.locked(false);c.time=.06;c:regen();c:regen();c:runAt(.06)
 check(c.j.stats.solves==2 and not c:state().dirty,'combat resume consumes one pending solve')
 records[#records+1]=c:record('combat-resume-'..style)
 -- Private/missing/error native rectangles and public recovery are compared
 -- byte-for-byte against baseline queries and complete actual mesh output.
 for _,mode in ipairs{'private','missing','error'}do
  c=fixture(style);c:warm();get=c.h.GetRect;local private=setmetatable({},{__add=function()error('private arithmetic')end,__lt=function()error('private comparison')end});c.e.issecretvalue=function(v)return rawequal(v,private)end
  local status=mode
  function c.h:GetRect()if status=='private'then return private,0,100,17 elseif status=='missing'then return elseif status=='error'then error('modeled native rectangle failure',0)end;return get(self)end
  c.time=.06;c:move();local ok,err=pcall(function()c:runAt(.06)end)
  check(mode=='error'and not ok and tostring(err)=='modeled native rectangle failure'or mode~='error'and ok,'native '..mode..' behavior is retained')
  check(c.e.inspect.phase()==nil,'native unavailable/error drops phase memo')
  status='public';c.time=.12;c.j:Invalidate(true);c:runAt(.12);check(c.j.stats.fallback==nil and c.j.stats.triangles>0,'public native recovery rebuilds complete mesh')
  records[#records+1]=c:record('native-'..mode..'-'..style)
 end
 -- Every supported fallback retains its previous scheduling/clock policy.
 for _,option in ipairs{'noScheduler','noTimer','noClock','manual'}do
  local opts={[option]=true};if option=='manual'then opts={noTimer=true,noScheduler=true}end
  c=fixture(style,opts);c:warm();c.time=.01;c:move();if option=='manual'then c.j:CommitLayout()else c:runAt(.01);c:runAt(.05)end
  check(c.j.stats.solves==2 and not c:state().dirty,'fallback '..option..' retains changed geometry')
  records[#records+1]=c:record('fallback-'..option..'-'..style)
 end
end
if arg[4]=='--json'then
 print(json({scope='standalone actual Core lifecycle/renderer fixture; no native/CPU claim',vm=_VERSION,expect=expect,checks=checks,records=records}))
else
 print('Border wake ownership: '..checks..' checks PASS; '..#records..' lifecycle/render scenarios; useful early-return/error recovery, same deadlines, stale callbacks, native privacy/reentry, combat and fallbacks; no native/CPU claim')
end
