-- Actual checkbox constructor/input configuration with throwing protected APIs.
-- Desktop permission model only; native vendor/combat/input acceptance pending.
local function read(p)local f=assert(io.open(p,"rb"));local s=f:read("*a"):gsub("\r\n","\n");f:close();return s end
local path=os.getenv("FLUX_VENDOR_INPUT_SOURCE")or"Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua"
local source=read(path)
local a=source:find("local function ConfigureAutoToggleInput",1,true)or assert(source:find("local function CreateCompactAutoToggle",1,true))
local b=assert(source:find("local function AttachAutoToggle",a,true))
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
for _,client in ipairs({"live","forever","classic","classic_era","classic_anniversary"})do
 local combat,permitted,opaque=false,true,{}
 local writes,queries,created=0,0,0
 local pending={}
 local methods={}
 for _,key in ipairs({"SetSize","SetPoint","SetFrameLevel","SetFrameStrata"})do methods[key]=function()end end
 function methods:GetFrameLevel()return 10 end
 function methods:GetFrameStrata()return"MEDIUM"end
 function methods:SetPropagateMouseClicks(v)check(not combat and permitted==true,"click setter never runs without permission");check(v==false,"click consumption retained");writes=writes+1 end
 function methods:SetPropagateMouseMotion(v)check(not combat and permitted==true,"motion setter never runs without permission");check(v==false,"motion consumption retained");writes=writes+1 end
 local e=setmetatable({AUTO_TOGGLE_SIZE=12,HasNativeSellJunkButton=function()return false end,UseClassicMerchantButtonStyle=function()return false end,
  InCombatLockdown=function()return combat end,issecretvalue=function(v)return rawequal(v,opaque)end,
  ApplyAutoToggleChrome=function(f)f.chrome=true end,
  ns={Flux={Combat={Defer=function(key,fn)pending[key]=fn end}}},
  C_RestrictedActions={CheckAllowProtectedFunctions=function(frame,silent)queries=queries+1;check(silent==true,"permission query is silent");if permitted=="error"then error("unavailable query")end;return permitted end}}, {__index=_G})
 e.CreateFrame=function(kind,_,parent)created=created+1;check(kind=="CheckButton","native checkbox retained");return setmetatable({parent=parent},{__index=methods})end
 local create,configure=assert(load(source:sub(a,b-1).."\nreturn CreateCompactAutoToggle,ConfigureAutoToggleInput","@production-vendor-input","t",e))()
 local host=setmetatable({},{__index=methods})
 local t=create(host);check(t.chrome and t.fluxIsCompactToggle and t.parent==host,"host/chrome/layout factory behavior remains")
 check(writes==2,"legal setup configures both propagation flags once")
 if configure then
  local before=queries;configure(t);check(writes==2 and queries==before,"settled toggle does not requery or rewrite input")
 end
 combat=true;local before=writes;local one=create(host);local two=create(host)
 check(writes==before,"combat construction never attempts protected propagation setters")
 if configure then configure(one);configure(one)end
 local n=0;for _ in pairs(pending)do n=n+1 end
 check(n==2,"combat retries coalesce separately for each owned toggle")
 combat=false;for key,fn in pairs(pending)do pending[key]=nil;fn()end
 check(writes==before+4,"both deferred toggles receive exact input settings after combat")
 for _,value in ipairs({false,opaque,"error"})do
  permitted=value;before=writes;local f=create(host)
  check(writes==before and not f.fluxInputConfigured,"denied/opaque/unavailable permission never attempts protected setters")
  if configure then permitted=true;configure(f);check(writes==before+2 and f.fluxInputConfigured,"later legal attachment can finish initialization")end
 end
 e.C_RestrictedActions=nil;permitted=true;before=writes;create(host)
 check(writes==before+2,"older clients retain out-of-combat initialization without the optional query")
end
print("Vendor toggle input permissions: "..checks.." checks PASS; native merchant/combat acceptance pending")
