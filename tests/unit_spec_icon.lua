-- Execute the real talent and profile selection functions with client-shaped APIs.
local f=assert(io.open((arg and arg[1]) or 'UnitFrames/FluxUnitFrames_Shared.lua','rb'));local src=f:read('*a'):gsub('\r\n','\n');f:close()
local function section(a,b)local x=assert(src:find(a,1,true));return src:sub(x,assert(src:find(b,x+#a,true))-1)end
local checks=0;local function check(v,m)assert(v,m);checks=checks+1 end
for _,modern in ipairs({false,true})do
 local points={10,11,10}
 local env=setmetatable({ns={},API={SafeGetNumber=function(x)return x or 0 end},GetNumTalentTabs=function()return 3 end,
 GetTalentTabInfo=function(tab) if modern then return tab,'tree','description',1000+tab,points[tab] end;return 'tree',1000+tab,points[tab],'background' end},{__index=_G})
 local tree=assert(load(section('local function GetSpecIconFromTalentTabs','local function CanInspectUnitForSpec')..'\nreturn GetSpecIconFromTalentTabs','tree','t',env))()
 check(tree(false)==1002,'most points wins for hybrid builds')
 points={20,20,0};check(tree(false)==1001,'ties choose first tree')
 points={0,0,0};check(tree(false)==nil,'no points no invented spec')
 env.UnitIsPlayer=function()return true end;env.GetSpecIconFromTalentTabs=tree
 env._G=env;env.FluxRespec_GetPlayerSpecIconOverride=function()return env.profile end
 local getter=section('GetSpecIcon = function(unit)','--- Used by Respec UI')
 local get=assert(load(getter..'\nreturn GetSpecIcon','spec','t',env))()
 env.profile=555;check(get('player')==555,'profile icon has priority')
 env.profile=nil;points={1,2,3};check(get('player')==1003,'no profile uses tree')
 env.GetSpecialization=function()return 2 end;env.GetSpecializationInfo=function()return 1,'name','description',777 end
 check(get('player')==777,'modern specialization fallback')
end
-- Current Classic namespaces return committed points in position seven.
local currentEnv=setmetatable({ns={Flux={Client={isEra=true}}},API={SafeGetNumber=function(x)return x or 0 end},
 C_SpecializationInfo={GetActiveSpecGroup=function()return 2 end,
 GetSpecializationInfo=function(tab,inspect,pet,target,sex,group)
  check(group==2,'active talent group used')
  return tab,'name','description',2000+tab,'role',0,tab*5,'background',99
 end}}, {__index=_G})
local currentTree=assert(load(section('local function GetSpecIconFromTalentTabs','local function CanInspectUnitForSpec')..'\nreturn GetSpecIconFromTalentTabs','current-classic','t',currentEnv))()
check(currentTree(false)==2003,'current classic uses committed points and icon fields')
local rf=assert(io.open('Respec/FluxRespec_Core.lua','rb'));local rs=rf:read('*a');rf:close()
local a=assert(rs:find('_G.FluxRespec_GetPlayerSpecIconOverride = function()',1,true))
local b=assert(rs:find('local specIconRefreshFrame',a,true))
local profileEnv={specDecorCacheValid=false,FluxRespec={ActiveProfileBuildMatches=function()return false end,GetActiveProfileBuildIcon=function()return 888 end}}
profileEnv._G=profileEnv
assert(load(rs:sub(a,b-1),'matching-profile','t',profileEnv))()
check(profileEnv.FluxRespec_GetPlayerSpecIconOverride()==nil,'nonmatching profile falls back')
profileEnv.FluxRespec.ActiveProfileBuildMatches=function()return true end
check(profileEnv.FluxRespec_GetPlayerSpecIconOverride()==888,'matching profile supplies icon')
-- Boot the actual client module. The resolver must consume its real namespace.
local cf=assert(io.open('Core/Client.lua','rb'));local clientSource=cf:read('*a');cf:close()
for _,case in ipairs({
 {project=1,version='1.60.1',branch='forever'},
 {project=2,version='1.15.9',branch='classic_era'},
 {project=5,version='2.5.6',branch='classic_anniversary'},
})do
 local ns={Flux={}}
 local ranks={5,20,15}
 local env=setmetatable({ns=ns,WOW_PROJECT_ID=case.project,WOW_PROJECT_MAINLINE=1,
 WOW_PROJECT_CLASSIC=2,WOW_PROJECT_BURNING_CRUSADE_CLASSIC=5,
 GetBuildInfo=function()return case.version,'70862','',160100 end,
 API={SafeGetNumber=function(x,default)return type(x)=='number' and x or default end},
 UnitIsPlayer=function()return true end,
 C_SpecializationInfo={GetActiveSpecGroup=function()return 1 end,
 GetSpecialization=function()return 1 end,
 GetSpecializationInfo=function(tab)
  if case.branch=='forever' then return 1482,'Mage','',626001,'DAMAGER',4,0,nil,0,true end
  return tab,'tree','description',3000+tab,'role',0,ranks[tab],'background',99
 end,GetCombatConfigIDForSpecGroup=function(group)check(group==1,'single spec group supported');return 100 end},
 C_Traits={GetConfigInfo=function(id)check(id==100,'active combat config used');return {treeIDs={11}} end,
 GetGroupDisplayInfoByTreeID=function(id)check(id==11,'configured tree used');return {
 {groupID=91,icon=3001},{groupID=92,icon=3002},{groupID=93,icon=3003}}end,
 GetGroupCurrencyInfo=function(id,groups)
 check(id==100 and #groups==3,'one bounded group currency query')
 return {{traitNodeGroupID=93,currencyInfos={{spent=ranks[3]}}},
 {traitNodeGroupID=91,currencyInfos={{spent=ranks[1]}}},
 {traitNodeGroupID=92,currencyInfos={{spent=ranks[2]}}}}
 end}
 },{__index=_G})
 env._G=env
 assert(load(clientSource,'actual-client-namespace','t',env))('_FluxUI',ns)
 check(ns.Flux.Client.branch==case.branch and ns.Client==nil,'actual client namespace '..case.branch)
 local functions=section('local function GetSpecIconFromTalentTabs','local function CanInspectUnitForSpec')
   ..section('GetSpecIcon = function(unit)','--- Used by Respec UI')..'\nreturn GetSpecIcon'
 local get=assert(load(functions,'actual-client-talent-resolver','t',env))()
 check(get('player')==3002,'real client uses most spent tree '..case.branch)
 ranks={30,20,15}
 check(get('player')==3001,'talent point changes update live icon '..case.branch)
 env.FluxRespec_GetPlayerSpecIconOverride=function()return 999 end
 check(get('player')==999,'matching profile remains first '..case.branch)
 env.FluxRespec_GetPlayerSpecIconOverride=function()return nil end
 check(get('player')==3001,'no/nonmatching profile restores talents '..case.branch)
 if case.branch=='forever' then
  ranks={20,20,0};check(get('player')==3001,'trait group ties keep first native header')
  ranks={0,0,0};check(get('player')==nil,'zero talent investment never duplicates class icon')
  env.C_Traits.GetConfigInfo=function()return nil end
  check(get('player')==nil,'loading config has no fabricated spec')
  env.C_Traits=nil;check(get('player')==nil,'missing trait API has no class placeholder')
 end
end
-- Ensure lightweight refresh closes over the local resolver, not an absent global.
check(src:find('local GetSpecIcon',1,true)<src:find('function UF.UpdatePlayerSpecIconOnly',1,true),'forward declared spec resolver')
print('PASS '..checks..' player spec selection checks')
