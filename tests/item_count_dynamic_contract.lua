-- Full real Item owner; native endpoints mocked. No helper-name/source-shape assertions.
-- Complements item_count_zero_authority.lua with order, dynamic lookup, errors and reentry.
local path=arg[1]or'Core/API/Item.lua'
local checks,cases=0,0
local function check(v,label)checks=checks+1;assert(v,label)end
local function pack(...)return{n=select('#',...),...}end
local function owner(configure)
 local e=setmetatable({Flux={}},{__index=_G});e._G=e
 e.C_Item=nil;e.GetItemCount=nil;e.pcall=pcall
 local trace={}
 local function mark(label,...)trace[#trace+1]={label=label,args=pack(...)}end
 if configure then configure(e,mark)end
 local file=assert(io.open(path,'rb'));local source=file:read('*a');file:close()
 local chunk
 if setfenv then chunk=assert(loadstring(source,'@actual-item-count-owner'));setfenv(chunk,e)
 else chunk=assert(load(source,'@actual-item-count-owner','t',e))end
 chunk('_FluxUI',{Flux=e.Flux})
 check(e.Flux.Item==e.Flux.API.Item,'same published Item facade')
 return e,e.Flux.Item,trace,mark
end
local function expected(label,...)return{label=label,args=pack(...)}end
local function order(actual,want,label)
 check(#actual==#want,label..' entry count')
 for n,row in ipairs(want)do
  check(actual[n].label==row.label and actual[n].args.n==row.args.n,label..' ordered call/arity '..n)
  for i=1,row.args.n do check(actual[n].args[i]==row.args[i],label..' exact argument '..n..'/'..i)end
 end
end
local function result(want,...)
 local values=pack(...);check(values.n==1 and values[1]==want,'one public return with expected result')
end
do
 local e,item,t=owner(function(e,mark)
  e.C_Item={GetItemCount=function(...)mark('M',...);return 7 end}
  e.GetItemCount=function()error('carried positive must not call legacy',0)end
 end)
 result(7,item.GetCount(117,false,'charges'))
 e.C_Item.GetItemCount=function(...)t[#t+1]=expected('M',...);return 0 end
 result(0,item.GetCount(117,false,false))
 order(t,{expected('M',117,false,true),expected('M',117,false,false)},'positive and authoritative zero');cases=cases+1
end
do
 local _,item,t=owner(function(e,mark)
  e.C_Item={GetItemCount=function(...)mark('M',...);local n=select('#',...);return n==3 and 2 or n==4 and 6 or 9 end}
  e.GetItemCount=function()error('positive extended modern result must not fall through',0)end
 end)
 result(9,item.GetCount(117,true,false,true,true))
 order(t,{expected('M',117,true,false),expected('M',117,true,false,true),expected('M',117,true,false,true,true)},'extended maximum');cases=cases+1
end
do
 local opaque={};local _,item,t=owner(function(e,mark)
  e.C_Item={GetItemCount=function(...)mark('M',...);local n=select('#',...);if n==3 then error(opaque,0)elseif n==4 then return 0 end;return nil end}
  local late=function(...)mark('Llate',...);return tostring(select('#',...)+1)end
  e.GetItemCount=function(...)mark('Lfirst',...);e.GetItemCount=late;return '4'end
 end)
 result(6,item.GetCount(117,true,false,true,true))
 order(t,{expected('M',117,true,false),expected('Lfirst',117,true,false),expected('M',117,true,false,true),expected('Llate',117,true,false,true),expected('M',117,true,false,true,true),expected('Llate',117,true,false,true,true)},'fresh legacy selection after protected error/zero/nil');cases=cases+1
end
do
 local e,item,t=owner(function(e,mark)e.GetItemCount=function(...)mark('L',...);return '8'end end)
 result(8,item.GetCount(117))
 e.C_Item={GetItemCount=function(...)t[#t+1]=expected('M',...);return 0 end}
 e.GetItemCount=function(...)t[#t+1]=expected('Lstrict',...);assert(select('#',...)==3,'legacy three args only');return 7 end
 result(7,item.GetCount(117,true,false))
 order(t,{expected('L',117,false,false),expected('M',117,true,false),expected('Lstrict',117,true,false),expected('M',117,true,false,false),expected('Lstrict',117,true,false,false),expected('M',117,true,false,false,false),expected('Lstrict',117,true,false,false,false)},'legacy-only and protected unsupported extended signatures');cases=cases+1
end
do
 local value,opaqueError={},{};local reads=0
 local e,item,t=owner(function(e,mark)
  e.C_Item={GetItemCount=function(...)mark('M',...);return value end}
  e.Flux.Secrets=setmetatable({},{__index=function(_,key)
   check(key=='SafeGetNumber','selected Secrets property');reads=reads+1;mark('secretLookup',reads)
   if reads==1 then return function()error('presence getter must not be cached',0)end end
   return function(v,default)mark('safe',v,default);check(v==value and default==0,'opaque converter arguments');return 11 end
  end})
 end)
 result(11,item.GetCount(117));check(reads==2,'separate Secrets presence and selected getter')
 e.tonumber=function()error(opaqueError,0)end
 local yes,err=pcall(item.GetCount,117);check(not yes and err==opaqueError,'unprotected conversion error preserves exact opaque object')
 order(t,{expected('M',117,false,false),expected('secretLookup',1),expected('secretLookup',2),expected('safe',value,0),expected('M',117,false,false)},'Secrets and raw converter failure');cases=cases+1
end
do
 local _,item,t=owner(function(e,mark)
  local late=function(...)mark('Mlate',...);return select('#',...)==4 and 9 or 6 end
  e.C_Item=setmetatable({},{__index=function(tab,key)
   check(key=='GetItemCount','fresh modern property selected');mark('lookupM')
   return function(...)mark('Mfirst',...);tab.GetItemCount=late;return 8 end
  end})
  e.tonumber=function(v)mark('numberFirst',v);e.tonumber=function(x)mark('numberLate',x);return tonumber(x)end;return tonumber(v)end
 end)
 result(9,item.GetCount(117,true,false,true,true))
 order(t,{expected('lookupM'),expected('Mfirst',117,true,false),expected('numberFirst',8),expected('Mlate',117,true,false,true),expected('numberLate',9),expected('Mlate',117,true,false,true,true),expected('numberLate',6)},'late modern/tonumber replacement');cases=cases+1
end
do
 local e,item,t,mark=owner();e.C_Item={GetItemCount=function(id,...)
  mark('M',id,...)
  if id==1 then result(0,item.GetCount(2,false,true))end
  return 0
 end}
 e.GetItemCount=function(id,...)mark('L',id,...);check(id==1,'inner carried zero never falls back');return 7 end
 result(7,item.GetCount(1,true,false,true,true))
 order(t,{expected('M',1,true,false),expected('M',2,false,true),expected('L',1,true,false),expected('M',1,true,false,true),expected('M',2,false,true),expected('L',1,true,false,true),expected('M',1,true,false,true,true),expected('M',2,false,true),expected('L',1,true,false,true,true)},'nested carriedOnly remains per invocation');cases=cases+1
end
do
 local e,item=owner();result(0,item.GetCount(nil))
 local opaque={};e.C_Item=setmetatable({},{__index=function()error(opaque,0)end})
 local yes,err=pcall(item.GetCount,117);check(not yes and err==opaque,'native property lookup error stays outside protected call');cases=cases+1
end
check(cases==8,'all finite direct groups ran')
print(('Item count dynamic contract: %d groups, %d checks'):format(cases,checks))
