-- Production junction renderer with native shared-alpha and anchor dependencies.
-- Component layout/input regressions run separately; these are decorative joins.
local function read(path)local f=assert(io.open(path,"rb"));local s=f:read("*a");f:close();return s end
local prefix=assert(read("tests/border_junctions.lua"):match("^(.-)local J=fixture%(%)"))
local fixture=assert(load(prefix.."\nreturn fixture","@border-anchor-fixture","t",_G))()
local checks=0
local function check(value,message)checks=checks+1;assert(value,message)end
for _,style in ipairs({1,2})do
 for _,name in ipairs({"FluxPetBar","FluxStanceBar","FluxActionStrip","FluxTrinketMenu","FluxCombatGrid_Main","FluxNonCombatGrid_Main"})do
  for _,mode in ipairs({"existing","allPoints","named"})do
   local j,new,piece,flush,objects,lock,selectStyle,queued,e=fixture()
   selectStyle(style,"class")
   local root=new(e.UIParent);root.name=name
   local button=new(e.UIParent,{0,-9,100,17})
   local initial=mode=="existing"and{{"LEFT",button,"LEFT",0,0}}or nil
   local h=piece(root,"Top",{0,-9,100,17},initial)
   if mode=="allPoints"then h:SetAllPoints(button)
   else
    function h:GetRect()e.rectReads=(e.rectReads or 0)+1;return button:GetLeft(),-9,100,17 end
    if mode=="named"then e.BorderSlotReference=button;h:SetPoint("LEFT","BorderSlotReference","LEFT",0,0)end
   end
   local v=piece(root,"Left",{41,-40,16,80})
   flush()
   check(j.stats.operations==1 and h:GetAlpha()==0 and v:GetAlpha()==0,name.." starts with its joined border")
   local count,solves=#objects,j.stats.solves;e.rectReads=0
   for _=1,100 do button:SetPoint("LEFT",e.UIParent,"LEFT",0,0);h:SetVertexColor(.2,.5,.8,1)end
   check(queued()==1,name.." coalesces repeated layout and repaint calls")
   flush()
   check(e.rectReads==1 and j.stats.solves==solves and #objects==count,name.." unchanged callbacks inspect only the reference and keep static joins")
   button.rect[1]=200;button:SetPoint("LEFT",e.UIParent,"LEFT",200,0)
   check(h:GetAlpha()==0,name.." retains committed art until the new layout is ready")
   flush()
   check(j.stats.operations==0 and h:GetAlpha()==1 and v:GetAlpha()==1,name.." repacking restores detached edges even when the parent rectangle is unchanged")
   button.rect[1]=0;button:SetPoint("LEFT",e.UIParent,"LEFT",0,0);flush()
   check(j.stats.operations==1 and h:GetAlpha()==0 and #objects==count,name.." reattachment reuses the existing join graphics")
   local source=piece(root,"Top",{0,11,100,17});flush()
   check(j.stats.operations>1 and source:GetAlpha()==0,name.." a newly created piece joins on the first settled pass")
   source:Hide();flush()
   check(j.stats.operations==1 and h:GetAlpha()==0,name.." disappearing button restores its former junction")
   source:Show();flush()
   check(j.stats.operations>1 and source:GetAlpha()==0,name.." reappearing button receives the current style without reload")
   source:Hide();flush()
   lock(true);button.rect[1]=200;button:SetPoint("LEFT",e.UIParent,"LEFT",200,0);flush()
   check(h:GetAlpha()==0 and queued()==0,name.." combat keeps the committed decorative mesh")
   lock(false)
   for _,o in ipairs(objects)do if o.OnEvent then o:OnEvent("PLAYER_REGEN_ENABLED")end end
   flush()
   check(j.stats.operations==0 and h:GetAlpha()==1,name.." deferred geometry reconnects after combat")
  end
 end
end
-- A sibling reference can itself be anchored to another layout owner. Cycles
-- are legitimate in the model and must not install duplicate observers.
do
 local j,new,piece,flush,objects,_,_,queued,e=fixture()
 local a,b=new(e.UIParent),new(e.UIParent)
 a.anchors={{"LEFT",b,"LEFT",0,0}};b.anchors={{"RIGHT",a,"RIGHT",0,0}}
 local root=new(e.UIParent);root.anchors={{"BOTTOM",a,"BOTTOM",0,0}}
 piece(root,"Top",{0,-9,100,17});piece(root,"Left",{41,-40,16,80});flush()
 local count=#objects;local old=j.stats.solves
 for _=1,50 do a:SetPoint("LEFT",b,"LEFT",0,0);b:SetPoint("RIGHT",a,"RIGHT",0,0)end
 flush()
 check(#objects==count and j.stats.solves==old and queued()==0,"cyclic anchor dependencies remain bounded and stable")
end
-- Secret anchor targets never become table keys or watched objects.
do
 local j,new,piece,flush,_,_,_,_,e=fixture()
 local secret=setmetatable({}, {__index=function()error("private reference inspected")end})
 e.issecretvalue=function(value)return value==secret end
 local root=new(e.UIParent)
 local h=piece(root,"Top",{0,-9,100,17},{{"LEFT",secret,"LEFT",0,0}})
 piece(root,"Left",{41,-40,16,80});flush()
 check(h:GetAlpha()==0 and j.stats.operations==1,"private anchor reference is skipped without disturbing public border geometry")
end
-- Execute the real completed action-strip layout path. Its rectangle can stay
-- fixed while packing/dragging and dependent chrome change underneath it.
do
 local moved,locked=false,false
 local sequence={}
 local function note(value)sequence[#sequence+1]=value end
 local flux={Bars={Hosts={ApplyChrome=function()note("chrome")end}},Combat={InLockdown=function()return locked end}}
 flux.Bars.RequestLayout=function()note("defer")end
 local env=setmetatable({FluxBorder={Junctions={CommitLayout=function()check(true,"layout commits dirty geometry without forcing a whole-HUD invalidation");note("border")end}},
  FluxUILayoutSqueeze={NotifyLayoutDependents=function()note("dependents")end},
  FluxUnifiedBorder={UpdateBorder=function()note("envelope")end}}, {__index=_G})
 assert(load(read("Bars/Layout.lua"),"@actual-action-layout","t",env))("_FluxUI",{Flux=flux})
 local layout=flux.Bars.Layout
 layout.ApplyMappings=function()note("mappings")end
 layout.ApplyVisual=function()note("visual");return moved end
 for _=1,100 do layout.Apply()end
 check(#sequence==200,"unchanged action content never dirties border geometry")
 moved=true;sequence={};layout.Apply()
 check(table.concat(sequence,",")=="mappings,visual,chrome,dependents,envelope,border","actual repack uses the final side-panel pose for the envelope and border commit")
 layout.ApplyVisual=function()note("visual");return false,true end
 sequence={};layout.Apply()
 check(table.concat(sequence,",")=="mappings,visual,dependents,envelope,border","shell repair before the border commit does not reskin unchanged buttons")
 locked=true;sequence={};layout.Apply()
 check(table.concat(sequence,",")=="defer","combat layout defers before requesting any border work")
end
print("Dynamic border layouts: "..checks.." checks PASS; both styles; six HUD families; preexisting/all-point/named anchors; new/hidden pieces; actual action-strip completion; no-op work; combat deferral; cycle/private guards. Native pixels/input/FPS pending")
