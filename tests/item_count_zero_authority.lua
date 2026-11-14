-- A valid modern zero must not resurrect a deprecated API's positive count.
local checks,failures=0,0
local zeroLegacyReads=0
local function check(ok,label)checks=checks+1;if not ok then failures=failures+1;print("FAIL "..label)end end
local path=arg[1]or"Core/API/Item.lua"
for _,family in ipairs({"retail","forever","classic","era","anniversary"})do
 local modern,legacy=0,0
 local env=setmetatable({}, {__index=_G});env._G=env
 local state={native=0,old=13,throws=false,missing=false}
 env.C_Item={GetItemCount=function(...)
  modern=modern+1;if state.throws then error("unsupported signature")end
  if state.missing then return nil end
  return state.native
 end}
 env.GetItemCount=function(...)legacy=legacy+1;return state.old end
 local flux={};assert(loadfile(path,"t",env))("_FluxUI",{Flux=flux})
 for _,id in ipairs({117,159,1251,118,2455,5514,22044,5512,6948,123456})do
  state.native,state.old=0,13
  local before=legacy
  check(flux.Item.GetCount(id,false,false)==0,family.." copy zero "..id)
  check(legacy==before,family.." zero does not fall through "..id)
  check(flux.Item.GetCount(id,false,true)==0,family.." use zero "..id)
  zeroLegacyReads=zeroLegacyReads+legacy-before
  state.native,state.old=3,0
  check(flux.Item.GetCount(id,false,false)==3,family.." positive modern count "..id)
 end
 state.missing=true;state.old=7
 check(flux.Item.GetCount(117,false,false)==7,family.." missing modern result falls back")
 state.missing=false;state.throws=true
 check(flux.Item.GetCount(117,false,false)==7,family.." failed modern query falls back")
 env.C_Item=nil
 check(flux.Item.GetCount(117,false,false)==7,family.." legacy-only clients remain supported")
 -- Preserve multi-signature bank/reagent/account maximum behavior.
 env.C_Item={GetItemCount=function(id,bank,uses,reagent,account)
  check(bank==true,family.." explicit bank preserved")
  return account and 9 or reagent and 6 or 2
 end}
 check(flux.Item.GetCount(117,true,false,true,true)==9,family.." extended count signature preserved")
 env.C_Item={GetItemCount=function()return 0 end}
 check(flux.Item.GetCount(117,true,false)==7,family.." bank zero retains existing legacy fallback")
 env.GetItemCount=function(...)
  assert(select("#",...)<=3,"legacy bank API only accepts three arguments")
  return 7
 end
 check(flux.Item.GetCount(117,true,false)==7,family.." strict legacy bank signature preserved")
end
print(("Item count zero authority: %d checks, %d failures; zeroLegacyReads=%d"):format(checks,failures,zeroLegacyReads))
assert(failures==0,"item count zero authority regression")
