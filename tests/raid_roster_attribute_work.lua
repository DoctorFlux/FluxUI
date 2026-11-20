-- Real secure OOC configurator; native roster execution stays authoritative.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local s=read(arg[1]or'RaidFrame/FluxRaidSecure.lua');local a=assert(s:find('function Secure.RefreshRosterLayout(',1,true));local b=assert(s:find('_G.FluxRaidSecure = Secure',a,true));local body=s:match('local ROSTER_LAYOUT = %[=%[(.-)%]=%]')
local checks=0;local function check(v,m)checks=checks+1;assert(v,m)end
local attr,counts,combat={}, {writes=0,executes=0,refs=0},false
local opaque=setmetatable({},{__eq=function()error('private compare')end})
local header={GetAttribute=function(_,k)return attr[k]end,SetAttribute=function(_,k,v)counts.writes=counts.writes+1;attr[k]=v end,SetFrameRef=function()counts.refs=counts.refs+1 end,GetFrameRef=function()error('ordinary GetFrameRef is not available')end}
local restricted={ExecutePaging=function()counts.executes=counts.executes+1;return true end}
local env=setmetatable({ROSTER_LAYOUT=body,Secure={},EnsureHub=function()return header,restricted end,InCombat=function()return combat end,issecretvalue=function(v)return rawequal(v,opaque)end},{__index=_G})
assert(load(s:sub(a,b-1),'@secure-roster-attributes','t',env))();local groups={{},{},{},{},{},{},{},{}};local container,mt={},{};local options={colStep=72,columnHeight=215,mtChildStep=66,mtExtraY=60}
check(env.Secure.RefreshRosterLayout(container,groups,mt,options),'first native preparation succeeds');local cold=counts.writes
for _=1,100 do check(env.Secure.RefreshRosterLayout(container,groups,mt,options),'unchanged reconciliation still executes native layout')end
check(counts.writes==cold,'unchanged roster reconciliation does not rewrite layout/snippet attributes')
check(counts.executes==101 and counts.refs==1010,'all native execution and frame-reference recovery remains')
options.colStep=73;check(env.Secure.RefreshRosterLayout(container,groups,mt,options),'changed geometry accepted');check(counts.writes==cold+1 and attr['roster-step']==73,'only changed geometry attribute written')
attr['roster-column-height']=opaque;check(env.Secure.RefreshRosterLayout(container,groups,mt,options),'restricted prior value conservatively restores authored attribute');check(counts.writes==cold+2,'private attribute never compared')
attr['_flux-roster-layout']='foreign';env.Secure.RefreshRosterLayout(container,groups,mt,options);check(attr['_flux-roster-layout']==body,'foreign snippet replacement is repaired')
local old={counts.writes,counts.executes,counts.refs};combat=true;check(not env.Secure.RefreshRosterLayout(container,groups,mt,options),'combat retains deferral contract');check(counts.writes==old[1]and counts.executes==old[2]and counts.refs==old[3],'zero protected configuration in combat')
combat=false;restricted.ExecutePaging=function()return false end;check(not env.Secure.RefreshRosterLayout(container,groups,mt,options),'native failure remains visible to existing fallback')
print('Secure roster attributes: '..checks..' checks PASS;100 warm reconciliations zero attribute writes vs800;native executes/reference recovery retained;public edits/private values/tamper/combat/failure paths. Native pending.')
