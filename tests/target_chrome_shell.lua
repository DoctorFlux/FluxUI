-- Actual target/ToT initializers with the real shared border factory. The
-- shared renderer's duplicate edges/corners are exercised by border_junctions.
local function read(p)local f=assert(io.open(p,"rb"));local s=f:read("*a");f:close();return s end
local prefix=assert(read("tests/border_types.lua"):match("^(.-)for _, forever in ipairs"))
local model=assert(load(prefix.."\nreturn model","@shared-border-fixture","t",_G))()
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local keys={"TL","TR","BL","BR","Top","Bottom","Left","Right"}
for _,forever in ipairs({false,true})do for _,placement in ipairs({1,2})do
 local e,b,db,new=model(forever,"all")
 local m=getmetatable(e.UIParent).__index
 function m:GetScale()return self.scale or 1 end
 function m:SetScale(v)self.scale=v end
 function m:GetEffectiveScale()return self:GetScale()*(self.parent and self.parent:GetEffectiveScale()or 1)end
 function m:GetWidth()return self.width or 300 end
 function m:GetHeight()return self.height or 100 end
 function m:ClearAllPoints()self.points={}end
 function m:IsShown()return self.shown end
 function m:IsVisible()return self.shown and(not self.parent or self.parent:IsVisible())end
 function m:SetShown(v)self.shown=v and true or false end
 function m:HookScript(event,fn)local old=self[event];self[event]=function(...)if old then old(...)end;fn(...)end end
 function m:UnregisterAllEvents()end
 function m:RegisterUnitEvent()end
 function m:SetAttribute()error("decorative layout must not write unit/action attributes")end
 local state={target=true,enabled=true,portrait=true}
 e.InCombatLockdown=function()return false end
 e.FluxUnitFrames_ShouldUseFlux=function()return state.enabled end
 e.FluxUnitFrames_ShouldShowPortrait=function()return state.portrait end
 e.FluxUnitFrames_GetPlayerTargetPlacement=function()return placement end
 e.GetRaidTargetIndex=function()end
 e.UnitExists=function()return state.target end;e.UnitIsVisible=e.UnitExists
 e.C_Timer={After=function()end}
 local init={};local UF={}
 local ns={UnitFrames=UF,Border=b,Flux={},CastBar={}}
 function UF.RegisterInitializer(unit,fn)init[unit]=fn end
 function UF.GetFramePublicLevel(f)return f.level or 10 end
 function UF.SetFramePublicLevel(f,v)f.level=v end
 function UF.GetFramePublicDimensions(f)return f:GetWidth(),f:GetHeight()end
 function UF.CreateBaseFrame(unit,parent,w,h)
  local f=new(parent);f.unit=unit;f:SetSize(w,h);b:ApplyTo(f,2,2,2,6)
  f.UpdatePartition=function()end;f.UpdateOuterBorder=function()end
  return f
 end
 function UF.CreateHealthBar(f)f.Health=new(f);return f.Health end
 function UF.CreatePowerBar(f)f.Power=new(f);return f.Power end
 function UF.CreatePortrait(f)f.PortraitFrame=new(f);b:ApplyTo(f.PortraitFrame,2,2,2,2)end
 function UF.CreateAtlasBorder(f)
  local a=new(e.UIParent);a._FluxBorderOwner=f;f.atlasBorderFrame=a
  b:ApplyTo(a,2,2,2,6);return a
 end
 function UF.CreateOuterBorder(f)
  local o=new(f);f.outerBorderFrame=o;o:SetSize(f:GetWidth(),f:GetHeight()+36)
  b:ApplyTo(o,2,2,2,6);return o
 end
 function UF.EnableAuras()end
 function UF.UpdateHealth()end;function UF.UpdatePower()end;function UF.UpdatePortrait()end
 function UF.SyncWatchedUnitFrameVisibility(f)f:SetShown(state.target)end
 function UF.SyncTargetPlaceholderVisibility(f)f.placeholderBorder:SetShown(not state.target)end
 e.FluxUnitFrames_ReanchorUnitFrameScreenPosition=function()end
 for _,name in ipairs({"UnitFrames/FluxUnitFrames_Target.lua","UnitFrames/FluxUnitFrames_TargetOfTarget.lua"})do
  assert(load(read(name),"@actual-"..name,"t",e))("_FluxUI",ns)
 end
 init.target();init.targettarget()
 local target,tot=assert(ns.TargetFrame),assert(ns.TargetOfTargetFrame)
 check(UF.SetupTargetChrome==nil and target._fluxTargetChrome==nil and tot._fluxTargetChrome==nil,"target and ToT use the common player/focus geometry path without a private shell")
 for _,f in ipairs({target,tot})do
  for _,owner in ipairs({f,f.atlasBorderFrame,f.outerBorderFrame})do
   check(owner.FluxBorderFrame:GetParent()==owner,"shared border artwork retains its original owner")
   check(owner.FluxBorderFrame.BackgroundFrame:GetParent()==owner,"shared backdrop stays below content under its original owner")
   for _,style in ipairs({1,2})do
    db.borderType=style
    for _,mode in ipairs({"atlas","class","custom"})do
     db.borderAccent=mode;b:RefreshAppearanceDependents()
     for _,key in ipairs(keys)do
      local t=assert(owner.FluxBorderFrame[key]);check(t:IsShown(),"all original caps/edges stay available to shared duplicate ownership")
      check(t._FluxBorderRunCaps==nil,"target does not impose hardcoded straight-divider endpoints on shared artwork")
     end
    end
   end
  end
 end
 for _,key in ipairs(keys)do check(target.PortraitFrame.FluxBorderFrame[key]:IsShown(),"normal portrait uses the same shared connected border as player/focus")end
 check(target.PortraitFrame.FluxBorderFrame._FluxBorderJunctionRole==nil,"portrait tint remains paint on the common connected geometry")
 local placeholder=assert(target.placeholderBorder)
 check(placeholder._FluxBorderOwner==target and placeholder.FluxBorderFrame~=nil,"no-target placeholder retains its logical target owner and original shared outline")
 for _=1,3 do
  state.target=false;target:UpdateFluxTargetPlaceholderVisibility();UF.SyncWatchedUnitFrameVisibility(target)
  check(placeholder:IsShown() and not target:IsShown(),"no-target state shows the independent placeholder and hides the actual target")
  state.target=true;target:UpdateFluxTargetPlaceholderVisibility();UF.SyncWatchedUnitFrameVisibility(target)
  check(not placeholder:IsShown() and target:IsShown(),"target reappearance restores original unit chrome without a raised shell")
 end
end end
print("Shared target chrome: "..checks.." checks PASS; actual target/ToT initializers; original geometry/backdrop ownership; both styles/all accents; portrait and no-target lifecycle; native pixels pending")
