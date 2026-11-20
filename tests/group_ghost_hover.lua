-- Actual binding snippets and detached-chrome constructors. Desktop models do
-- not certify native protected execution, taint or group-transition timing.
local function read(path)
    local f=assert(io.open(path,"rb"));local s=f:read("*a"):gsub("\r\n","\n");f:close();return s
end
local bindingPath=arg[1] or "Binding/Input/FluxMouseoverKeybind.lua"
local shared=read(arg[2] or "UnitFrames/FluxUnitFrames_Shared.lua")
local fixtureText=read("tests/raid_binding_cast.lua")
local prefix=fixtureText:sub(1,assert(fixtureText:find("local function exercise(client, body)",1,true))-1)
local fixtureEnv=setmetatable({arg={bindingPath}},{__index=_G})
local fixture=assert(load(prefix.."\nreturn fixture","@group-ghost-fixture","t",fixtureEnv))()
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
for _,client in ipairs({"live","forever","classic","classic_era","classic_anniversary"})do
    local e,module,cell,fire,route,event=fixture(client)
    local party=cell("FluxUnitFrameOuter_party1",true)
    party.attrs.unit="party1"
    local pet=cell("FluxUnitFrameOuter_partypet1",true);pet.attrs.unit="partypet1"
    local target=cell("FluxUnitFrameOuter_party1target",true);target.attrs.unit="party1target"
    local raid=cell("FluxRaidGrp1Unit1",true);raid.attrs.unit="raid1"
    local aura=cell("FluxPartyAura",false,party);aura.attrs.unit=nil
    for _,f in ipairs({party,pet,target,raid})do module:RegisterFrame(f)end
    route({"Q","MOUSEWHEELUP"},{"/cast Heal","/cast Heal"})
    e.units={party1=false,partypet1=false,party1target=false,raid1=false,raid2=false}
    e.combat=true
    local writes=e.writes
    fire(party,"OnEnter")
    check(not next(party.binds),client..": nonexistent party slot cannot arm secure hover overrides")
    for _,f in ipairs({pet,target,raid})do
        fire(f,"OnEnter");check(not next(f.binds),client..": absent pet/target/raid slot cannot arm")
    end
    -- Join after combat begins: prepared frames and routing become usable.
    e.units.party1=true;e.units.partypet1=true;e.units.party1target=true
    fire(party,"OnEnter");check(party.binds.Q,client..": combat join enables a real prepared party member")
    fire(aura,"OnEnter");check(aura.binds.Q,client..": aura resolves its registered parent's unit")
    -- No mouse movement; the engine reassigns/removes a unit attribute.
    e.units.party1=false
    e.NativeAttribute(party,"unit",nil)
    check(not next(aura.binds) and not next(party.binds),client..": removed unit clears an active child override immediately")
    e.units.party2=true;e.NativeAttribute(party,"unit","party2")
    check(aura.binds.Q,client..": valid reassignment under the cursor can resume securely")
    -- Mouseover can disappear while shown geometry remains (no OnLeave).
    e.units.party2=false
    e.NativeAttribute(e.FluxClickCastHeader,"unit-exists","false")
    check(not next(aura.binds),client..": vanished source cannot keep bindings merely because its rect is hovered")
    -- Party to raid: real parent hide takes the outer/aura out of visibility.
    e.units.raid1=true;e.units.party2=true;party.shown=false
    fire(party,"OnHide");fire(aura,"OnHide")
    fire(party,"OnEnter");check(not next(party.binds),client..": hidden party frame cannot rearm after raid conversion")
    fire(raid,"OnEnter");check(raid.binds.Q,client..": prepared raid frame casts after combat conversion")
    e.units.raid2=true;e.NativeAttribute(raid,"unit","raid2")
    check(raid.binds.Q and raid.attrs.unit=="raid2",client..": secure raid unit replacement follows the new unit")
    -- A disappearing old party slot must not clear another active surface.
    e.NativeAttribute(party,"unit",nil)
    check(raid.binds.Q,client..": stale party attribute change preserves the raid peer's override")
    e.units.raid2=false;e.NativeAttribute(raid,"unit",nil)
    check(not next(raid.binds),client..": combat raid leave clears the final active override")
    -- Raid back to party, then the whole group disappears.
    raid.shown=false;fire(raid,"OnHide")
    party.shown=true;aura.shown=true;e.units.party1=true;e.NativeAttribute(party,"unit","party1")
    fire(party,"OnEnter");check(party.binds.Q,client..": combat conversion back to party resumes without Lua registration")
    fire(party,"OnHide");check(not next(party.binds),client..": final combat leave clears without OnLeave")
    check(e.writes==writes,client..": combat joins/leaves/reassignments make no ordinary protected writes")
    e.combat=false;event("PLAYER_REGEN_ENABLED")
    local dock=cell("HiddenGroupDock",false);dock.attrs.unit=nil;dock.shown=false
    party.parent=dock;party.shown=true
    function party:IsMouseOver()return true end
    e.GetMouseFoci=function()return {party}end
    local binding=read(bindingPath)
    local scanStart=assert(binding:find("local function FrameUnderMouse(f)",1,true))
    local scanEnd=assert(binding:find("function FluxMouseoverKeybind:HasHoverRoutingActive()",scanStart,true))
    local scan=assert(load("local registeredFrames,Flux=...\n"..binding:sub(scanStart,scanEnd-1).."\nreturn _PerformHoverContextScan",
        "@actual-group-hover-scan","t",e))({party},e.ns.Flux)
    check(not scan(),client..": hidden group ancestor excludes stale mouse-focus attribution")
    e.GetMouseFoci=nil
    check(not scan(),client..": hidden group ancestor excludes geometric hover fallback")
end

-- The screenshot's exact source is this detached separator constructor.
local a=assert(shared:find('local sepContainer = CreateFrame("Frame", nil, UIParent)',1,true))
local b=assert(shared:find("    -- Create Separators (Early)",a,true))
local ctor=shared:sub(a,b-1)
local atlasA=assert(shared:find("function UF.CreateAtlasBorder(frame, borderInsetY)",1,true))
local atlasB=assert(shared:find("-- Update Atlas Border",atlasA,true))
local atlasCtor=shared:sub(atlasA,atlasB-1)
for _,client in ipairs({"live","forever","classic","classic_era","classic_anniversary"})do
    local E=setmetatable({UF={},ns={}},{__index=_G})
    local methods={}
    local function frame(parent)return setmetatable({parent=parent,shown=true,hooks={},scale=1},{__index=methods})end
    function methods:IsShown()return self.shown end
    function methods:IsVisible()return self.shown and(not self.parent or self.parent:IsVisible())end
    function methods:HookScript(name,fn)
        local old=self.hooks[name]
        self.hooks[name]=function(...)if old then old(...)end;fn(...)end
    end
    local function shown(self,value)
        local old=self:IsVisible();self.shown=value;local current=self:IsVisible()
        if old~=current then local fn=self.hooks[current and"OnShow"or"OnHide"];if fn then fn(self)end end
    end
    function methods:Show()shown(self,true)end
    function methods:Hide()shown(self,false)end
    function methods:SetShown(v)shown(self,v)end
    function methods:GetEffectiveScale()return 1 end
    function methods:GetFrameStrata()return "MEDIUM"end
    function methods:GetFrameLevel()return 5 end
    function methods:SetScale(v)self.scale=v end
    function methods:SetFrameStrata()end
    function methods:SetFrameLevel()end
    function methods:SetPoint()end
    function methods:EnableMouse(v)self.mouse=v end
    E.UIParent=frame();E.CreateFrame=function(_,_,parent)return frame(parent)end
    local dock=frame(E.UIParent);dock.shown=false
    local member=frame(dock);member.unit="party4"
    local sep=assert(load("local frame,unit,UF=...\n"..ctor.."\nreturn sepContainer","@actual-separator","t",E))(member,member.unit,E.UF)
    member:Hide() -- Already effectively hidden: native OnHide does not fire.
    check(not sep:IsShown(),client..": separator is never exposed for a party member created under a hidden dock")
    assert(load(atlasCtor,"@actual-atlas","t",E))()
    member.shown=true -- Locally shown while the dock remains hidden.
    local atlas=E.UF.CreateAtlasBorder(member)
    check(not atlas:IsShown(),client..": atlas uses effective visibility under a hidden ancestor")
    check(sep.mouse==false and atlas.mouse==false,client..": detached decorations never own mouse input")
    -- Trigger the actual callbacks as native visibility changes, in combat too.
    dock.shown=true
    member.hooks.OnShow(member)
    check(sep:IsShown() and atlas:IsShown(),client..": real member visibility reveals its detached decoration")
    dock.shown=false;member.hooks.OnHide(member)
    check(not sep:IsShown() and not atlas:IsShown(),client..": group disappearance hides all detached decoration")
end
print(("Group ghost hover: %d checks; five client policies; combat group/attribute/hide/child transitions and screenshot chrome source; native VM pending"):format(checks))
