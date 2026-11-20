-- Actual helper/renderer lifecycle. Native latency/pixels/taint pending.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local core=read(arg[1]or'Core/BorderJunctions.lua')..'\nreturn {owner=StaticUnitOwner,phase=function(v)fallbackChains=v end,current=function()return fallbackChains end}'
local prefix=assert(read('tests/border_junctions.lua'):match('^(.-)local J=fixture%(%)'))
local old='assert(load(read("Core/BorderJunctions.lua"),"@Core/BorderJunctions.lua","t",e))("_FluxUI",{Border=B})'
local at=assert(prefix:find(old,1,true));prefix=prefix:sub(1,at-1)..'e.ownerTest=assert(load('..string.format('%q',core)..',"@owner-phase-actual-core","t",e))("_FluxUI",{Border=B})'..prefix:sub(at+#old)
local fixture=assert(load(prefix..'\nreturn fixture','@owner-phase-fixture','t',_G))()
local checks=0;local function check(v,m)checks=checks+1;assert(v,m)end
for _,style in ipairs{1,2}do
 local j,new,piece,flush,objects,_,choose,_,e=fixture();choose(style,'class')
 local api=e.ownerTest;local root=new(e.UIParent);root.unit='focus';root._FluxBorderStatic=true
 local chain=e.UIParent;for _=1,8 do chain=new(chain)end;local texture=new(chain,nil,'Texture')
 local m=getmetatable(root).__index;local old=m.GetParent;local reads=0
 function m:GetParent()reads=reads+1;return old(self)end
 local phase={};api.phase(phase);check(api.owner(texture)==nil,'deep ordinary HUD chain has no unit owner')
 local before=reads;for _=1,100 do check(api.owner(texture)==nil,'complete public nonunit result may be reused')end
 check(reads==before and phase.owners[texture]==false,'complete public miss avoids repeating all native ancestor reads')
 local secret=setmetatable({}, {__index=function()error('opaque owner indexed')end,__eq=function()error('opaque owner compared')end,__tostring=function()error('opaque owner formatted')end})
 e.issecretvalue=function(v)return rawequal(v,secret)end
 local query=new(chain,nil,'Texture');query.parent=secret
 check(api.owner(query)==nil and phase.owners[query]==nil,'private ancestor cannot publish a negative commit owner entry')
 query.parent=root;check(api.owner(query)==root,'same-phase public recovery after private parent is observed')
 e.issecretvalue=function(v)return rawequal(v,secret)or rawequal(v,root)end
 check(api.owner(query)==nil and phase.owners[query]==nil,'a cached owner currently marked private is never returned or retained')
 e.issecretvalue=function(v)return rawequal(v,secret)end
 check(api.owner(query)==root,'public owner recovery after cache rejection remains current')
 local metadata=new(chain);metadata._FluxBorderOwner=secret
 check(api.owner(metadata)==nil and phase.owners[metadata]==nil,'private explicit owner cannot publish a false result')
 metadata._FluxBorderOwner=root;check(api.owner(metadata)==root,'explicit owner public recovery remains fresh after incomplete walk')
 local missing={};check(api.owner(missing)==nil and phase.owners[missing]==nil,'missing native parent method is not treated as a complete nonunit chain')
 missing.GetParent=function()return root end;check(api.owner(missing)==root,'same-phase newly available parent method remains visible')
 local privateGetter={GetParent=secret}
 check(api.owner(privateGetter)==nil and phase.owners[privateGetter]==nil,'private parent method is incomplete without calling or truth-testing it')
 privateGetter.GetParent=function()return root end;check(api.owner(privateGetter)==root,'private parent method recovery is current within the same phase')
 local cycle=new(e.UIParent);cycle.parent=cycle
 check(api.owner(cycle)==nil and phase.owners[cycle]==nil,'cycle/budget exhaustion cannot publish a false owner result')
 cycle.parent=root;check(api.owner(cycle)==root,'cycle recovery in the same phase is not poisoned')
 local deep=root;for _=1,34 do deep=new(deep)end
 check(api.owner(deep)==nil and phase.owners[deep]==nil,'too-deep ownership remains uncached at the existing32-step bound')
 deep.parent=root;check(api.owner(deep)==root,'depth-budget recovery uses the current hierarchy')
 check(api.owner(secret)==nil,'private query is rejected before cache lookup or metadata access')
 -- Cache scope ends before source mutations/live paint: ordinary hierarchy
 -- changes in another phase and outside the phase always re-read native state.
 api.phase(nil);texture.parent=root;check(api.owner(texture)==root,'hierarchy change after the phase is read fresh')
 texture.parent=e.UIParent;check(api.owner(texture)==nil,'outside-phase negative/positive identity is never retained')
 api.phase({});check(api.owner(texture)==nil,'a new source-read commit phase starts with no old identity')
 texture._FluxBorderOwner=secret;api.phase(nil);check(api.owner(texture)==nil,'private owner outside the phase never receives cached public identity')
 texture._FluxBorderOwner=nil;api.phase({});j:ReleaseAll();check(api.current()==nil,'rollback/release clears the whole existing availability/owner phase')
 piece(root,'Top',{0,-9,100,17});piece(root,'Left',{41,-40,16,80});flush()
 check(api.current()==nil and j.stats.fallback==nil,'successful actual commit clears its read-only owner phase')
end
print('Render owner phase: '..checks..' checks PASS; complete-public negatives only; private/missing/cycle/budget recovery; live hierarchy freshness; query guards; actual commit/release cleanup; both styles')

