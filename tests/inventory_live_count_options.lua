-- Canonical live-count options and public/private region-order regression; native hook/client gates remain separate.
-- Whole Index owner; fixed snapshot/native endpoint models only.
-- No secure-hook behavior is simulated as native evidence.
local source=arg[1] or 'Inventory/Index.lua';local checks,cases=0,0;local names={}
local function eq(a,b,label)checks=checks+1;assert(a==b,(label or'')..': '..tostring(a)..' ~= '..tostring(b))end
local function ok(v,label)checks=checks+1;assert(v,label)end
local function pack(...)return{n=select('#',...),...}end
local regions={'bags','bank','warband','equip','mail','void','auctions','guild'}
local function boot(family)
 local h={family=family,warband=true,reliable=true,native=17,caps=0,nums=0,rels=0,args={},trace={},opaque={}}
 local e=setmetatable({},{__index=_G});e._G=e
 local inv={snapshots={}}
 for i,k in ipairs(regions)do inv.snapshots[k]={counts={[123]=2^(i-1)},byBag={},bySlot={},byIndex={}}end
 inv.HasWarband=function()h.caps=h.caps+1;h.trace[#h.trace+1]='cap'..h.caps;if h.cap then return h.cap(h.caps)end;return h.warband end
 inv.IsReliable=function()h.rels=h.rels+1;h.trace[#h.trace+1]='rel'..h.rels;if h.rel then return h.rel(h.rels)end;return h.reliable end
 local f={Inventory=inv,Item={},Secrets={SafeGetNumber=function(v,d)return type(v)=='table'and v.safe or d end}}
 f.Item.GetCount=function(...)
  local args=pack(...);h.args[#h.args+1]=args;h.trace[#h.trace+1]='native'
  if h.call then return h.call(args)end;return h.native
 end
 assert(loadfile(source,'t',e))('_FluxUI',{Flux=f})
 e.tonumber=function(v,...)
  h.nums=h.nums+1;h.trace[#h.trace+1]='num'..h.nums
  if h.number then return h.number(v,h.nums,...)end
  return tonumber(v,...)
 end
 h.e,h.inv,h.f,h.index=e,inv,f,inv.Index
 h.original=h.index.GetCount
 function h:proxy(values)
  local hits={};local p=setmetatable({},{__index=function(_,key)
   hits[key]=(hits[key]or 0)+1;h.trace[#h.trace+1]='o.'..key
   local v=values[key];if type(v)=='function'then return v(hits[key])end;return v
  end,__newindex=function()error(h.opaque,0)end})
  return p,hits
 end
 return h
end
local function test(name,fn)
 cases=cases+1;names[#names+1]=name
 local passed,err=pcall(fn);if not passed then error(name..': '..tostring(err),0)end
end
for _,family in ipairs({'Retail','Forever','Classic','Era','Anniversary'})do
 test(family..'/public-and-live-eight-region-order',function()
  local h=boot(family);h.reliable=false;local stored=h.inv.snapshots;local order={}
  h.inv.snapshots=setmetatable({},{__index=function(_,key)order[#order+1]=key;return stored[key]end})
  local opts={bags=true,bank=true,warband=true,equipped=true,mail=true,void=true,auctions=true,guild=true,charges=false}
  eq(h.index.GetCount(123,opts),255);eq(table.concat(order,','),'bags,bank,warband,equip,mail,void,auctions,guild')
  order={};eq(h.index.GetLiveCount(123,opts),255);eq(table.concat(order,','),'bags,bank,warband,equip,mail,void,auctions,guild')
  eq(h.caps,3);eq(#h.args,0)
 end)
 test(family..'/canonical-two-passes',function()
  local h=boot(family);eq(h.index.GetLiveCount('123'),17);eq(h.caps,2);eq(h.nums,3);eq(#h.args,1)
  local a=h.args[1];eq(a.n,5);eq(a[1],123);eq(a[2],false);eq(a[3],true);eq(a[4],false);eq(a[5],false)
 end)
 test(family..'/first-and-second-warband-distinct',function()
  local h=boot(family);h.cap=function(n)return n==1 end;h.native=0;h.reliable=false
  local p,seen=h:proxy({bags=false,warband=true,charges=function(n)return n==2 end})
  eq(h.index.GetLiveCount('123',p),0);eq(h.caps,2);eq(seen.charges,2);eq(#h.args,1)
  eq(h.args[1][2],true);eq(h.args[1][3],true);eq(h.args[1][4],true);eq(h.args[1][5],true)
  eq(table.concat(h.trace,','),'num1,o.bags,o.bank,o.warband,o.equipped,o.mail,o.void,o.auctions,o.guild,o.includeBank,o.includeBank,cap1,o.charges,o.charges,num2,cap2,rel1,native,num3')
 end)
 test(family..'/first-false-capability-cannot-be-resurrected',function()
  local h=boot(family);h.cap=function(n)return n==2 end;h.native=0;h.reliable=false
  eq(h.index.GetLiveCount(123,{bags=false,warband=true}),0);eq(h.caps,2);eq(h.args[1][5],false)
 end)
 test(family..'/second-charges-selects-current-override',function()
  local h=boot(family);local calls,held=0
  local p=h:proxy({bags=false,warband=true,charges=function(n)
   if n==2 then h.index.GetCount=function(id,o)calls=calls+1;held=o;eq(select('#',id,o),2);eq(o.charges,false);o.warband=false;return 8 end end
   return n==2
  end})
  eq(h.index.GetLiveCount(123,p),17);eq(calls,1);eq(h.caps,1);ok(held~=p);eq(h.args[1][2],true);eq(h.args[1][3],true);eq(h.args[1][5],false)
 end)
 test(family..'/second-charges-restores-canonical',function()
  local h=boot(family);local called=0;h.index.GetCount=function()called=called+1;return 44 end
  local p=h:proxy({charges=function(n)if n==2 then h.index.GetCount=h.original end;return false end})
  eq(h.index.GetLiveCount(123,p),17);eq(called,0);eq(h.caps,2);eq(h.args[1][3],false)
 end)
 test(family..'/fresh-override-table-and-first-return',function()
  local h=boot(family);local rows={};h.reliable=false
  h.index.GetCount=function(...)local a=pack(...);eq(a.n,2);eq(a[1],123);rows[#rows+1]=a[2];a[2].bank=99;return 31,nil,87 end
  eq(h.index.GetLiveCount(123,{charges=false}),31);eq(h.index.GetLiveCount(123,{charges=false}),31)
  ok(rows[1]~=rows[2]);eq(rows[2].bags,true);eq(rows[2].warband,false);eq(rows[2].charges,false);eq(#h.args,0);eq(h.caps,2)
 end)
 test(family..'/fallback-late-native-getter-mutation',function()
  local h=boot(family);local held,lookups
  h.index.GetCount=function(_,o)held=o;return 8 end;lookups=0
  local fn=h.f.Item.GetCount
  h.f.Item=setmetatable({},{__index=function(_,key)
   eq(key,'GetCount');lookups=lookups+1;if lookups==2 then held.warband=false end;return fn
  end})
  eq(h.index.GetLiveCount(123,{warband=true}),17);eq(lookups,2);eq(h.args[1][2],true);eq(h.args[1][4],true);eq(h.args[1][5],false)
 end)
 test(family..'/fallback-reliability-mutation',function()
  local h=boot(family);local held;h.index.GetCount=function(_,o)held=o;return 8 end
  h.rel=function()held.warband=false;return true end
  eq(h.index.GetLiveCount(123,{warband=true}),17);eq(h.args[1][2],true);eq(h.args[1][5],false)
 end)
 test(family..'/second-tonumber-invalid-snapshot-id',function()
  local h=boot(family);h.number=function(v,n)if n==2 then return nil end;return tonumber(v)end
  eq(h.index.GetLiveCount('123'),17);eq(h.caps,1);eq(h.nums,3);eq(h.args[1][1],123)
 end)
 test(family..'/second-tonumber-opaque-error',function()
  local h=boot(family);h.number=function(v,n)if n==2 then error(h.opaque,0)end;return tonumber(v)end
  local a,b=pcall(h.index.GetLiveCount,'123');eq(a,false);eq(b,h.opaque);eq(h.caps,1);eq(#h.args,0)
 end)
 test(family..'/second-capability-replaces-only-future-getter',function()
  local h=boot(family);local overrideCalls=0
  h.cap=function(n)if n==2 then h.index.GetCount=function()overrideCalls=overrideCalls+1;return 99 end end;return true end
  eq(h.index.GetLiveCount(123),17);eq(overrideCalls,0);h.reliable=false
  eq(h.index.GetLiveCount(123),99);eq(overrideCalls,1);eq(#h.args,1);eq(h.caps,3)
 end)
 test(family..'/nested-second-charges-local-state',function()
  local h=boot(family);local p=h:proxy({charges=function(n)
   if n==2 then eq(h.index.GetLiveCount(123,{bags=false,bank=true,charges=false}),17)end;return true
  end})
  eq(h.index.GetLiveCount(123,p),17);eq(h.caps,4);eq(#h.args,2);eq(h.args[1][2],true);eq(h.args[1][3],false);eq(h.args[2][2],false);eq(h.args[2][3],true)
 end)
 test(family..'/snapshot-owner-replaced-between-region-reads',function()
  local h=boot(family);h.reliable=false;local bags={counts={[123]=2}};local after={bank={counts={[123]=99}}}
  h.inv.snapshots=setmetatable({},{__index=function(_,key)eq(key,'bags');h.inv.snapshots=after;return bags end})
  eq(h.index.GetLiveCount(123,{bank=true}),101);eq(#h.args,0);eq(h.caps,2)
 end)
 test(family..'/callable-table-getter-arity',function()
  local h=boot(family);local calls=0
  h.index.GetCount=setmetatable({},{__call=function(self,...)local a=pack(...);calls=calls+1;eq(a.n,2);eq(a[1],123);eq(type(a[2]),'table');return nil,87 end})
  eq(h.index.GetLiveCount(123),17);eq(calls,1);eq(h.caps,1);eq(#h.args,1)
 end)
 test(family..'/native-error-identity',function()
  local h=boot(family);h.call=function()error(h.opaque,0)end
  local a,b=pcall(h.index.GetLiveCount,123);eq(a,false);eq(b,h.opaque);eq(#h.args,1);eq(h.caps,2)
 end)
 test(family..'/false-includeBank-alias-short-circuit',function()
  local h=boot(family);local p,seen=h:proxy({bank=true,warband=true,includeBank=false,charges=false})
  eq(h.index.GetLiveCount(123,p),17);eq(seen.includeBank,1);eq(seen.charges,2);eq(h.caps,2);eq(h.args[1][2],false);eq(h.args[1][5],false)
 end)
end
print('FOCUSED',cases,checks)
for _,name in ipairs(names)do print('CASE',name)end
