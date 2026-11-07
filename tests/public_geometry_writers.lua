-- Execute the actual layout owners against the production public ledger. Native
-- dimensions are deliberately unreadable; each size write must have recorded its
-- public arguments before the write, not reconstructed them from a child.
local function read(path)local f=assert(io.open(path,"rb"));local s=f:read("*a"):gsub("\r\n","\n");f:close();return s end
local shared=read("UnitFrames/FluxUnitFrames_Shared.lua")
local function slice(s,a,b)local i=assert(s:find(a,1,true),a);return s:sub(i,assert(s:find(b,i+#a,true),b)-1)end
local checks=0
local function check(v,why)checks=checks+1;assert(v,why)end
for _,client in ipairs({"era","anniversary","live","forever"})do
    local opaque={secret=true};local e=setmetatable({},{__index=_G});e._G=e
    local uf={UsesHudUnitBars=function()return client=="live"or client=="forever"end}
    local api={IsSecretValue=function(v)return v==opaque end,CanAccessValue=function(v)return v~=opaque end}
    local ns={UnitFrames=uf,API=api};local combat=false
    e.InCombatLockdown=function()return combat end
    local function run(code)return assert(load(code,"@production-layout-owner","t",e))("_FluxUI",ns)end
    run("local _,ns=...;local UF,API=ns.UnitFrames,ns.API\n"..slice(shared,"local function ValueIsSecret(value)","local function PlayerDeadOrGhost(unit)"))
    local function frame(w,h)
        local f={unit="player",_fluxLayoutWidth=w,_fluxLayoutHeight=h,_fluxLayoutBaseWidth=w,scale=1}
        function f:GetWidth()return opaque end;function f:GetHeight()return opaque end
        function f:SetWidth(v)check(self._fluxLayoutWidth==v,"width writer records public argument first");self.actualWidth=v end
        function f:SetHeight(v)check(self._fluxLayoutHeight==v,"height writer records public argument first");self.actualHeight=v end
        function f:SetSize(x,y)check(self._fluxLayoutWidth==x and self._fluxLayoutHeight==y,"size writer records both public arguments first");self.actualWidth,self.actualHeight=x,y end
        function f:UpdatePartition()self.partitions=(self.partitions or 0)+1 end
        function f:UpdateAtlasBorder()end;function f:UpdateOuterBorder()end
        function f:SetScale(v)self.scale=v end;function f:GetScale()return self.scale end
        function f:GetEffectiveScale()return self.scale end
        function f:GetParent()return self.parent end;function f:ClearAllPoints()end;function f:SetPoint()end
        return f
    end
    e.FluxUILayoutSqueeze={GetEffectiveEmulatedDependentXFactorForUnitFrames=function()return .75 end}
    run("local _,ns=...;local UF=ns.UnitFrames\n"..slice(shared,"local emulatedSqueezeFrames = {}","function UF.RegisterEmulatedHorizontalSqueeze(frame)"))
    local f=frame(200,60);uf.ApplyEmulatedHorizontalSqueezeForFrame(f)
    check(f.actualWidth==150 and f.partitions==1,"real squeeze writer and relayout route")
    combat=true;uf.ApplyEmulatedHorizontalSqueezeForFrame(f);check(f.partitions==1,"squeeze defers protected size writes in combat");combat=false

    -- Focus target metrics preserve the full visual width and HP partition,
    -- even when the focus/outer-border native geometry is inaccessible.
    uf.GetFluxStylePartitionHealthHeight=function(h)return(h-8)*.6-1 end
    local focus=frame(120,100);focus.outerBorderFrame={GetWidth=function()return opaque end};focus.PortraitFrame={IsShown=function()return true end};ns.FocusFrame=focus
    local match=run(slice(read("UnitFrames/FluxUnitFrames_FocusTarget.lua"),"local addonName, ns = ...","local ftInitialized = false").."\nreturn MatchFocusBarMetrics")
    local target=frame(119,50);match(target)
    check(target.actualWidth==222 and math.abs(target.actualHeight-58.2)<1e-8,"real focus target matches public focus visual metrics")
    combat=true;local before=target.actualWidth;focus._fluxLayoutWidth=200;match(target)
    check(target.actualWidth==before,"focus target retains protected size until combat ends");combat=false

    -- The pet-target updater is a real nested function, executed unchanged with
    -- its normal owned locals and public PetFrame ledger.
    local pet=frame(200,77);ns.PetFrame=pet;local pt=frame(35,50);pt.parent=pet
    pt._petTargetEventFrame={IsEventRegistered=function()return false end,RegisterEvent=function()end}
    local oldSqueeze=uf.ApplyEmulatedHorizontalSqueezeForFrame;uf.ApplyEmulatedHorizontalSqueezeForFrame=nil
    local code="local _,ns,frame=...;local UF,API=ns.UnitFrames,ns.API;local ANCHOR_GAP=2;local GetPetTargetBarWidth=function()return 41 end\n"
        ..slice(read("UnitFrames/FluxUnitFrames_PetTarget.lua"),"    local function UpdatePosition()","    frame._fluxRefreshLayout = UpdatePosition").."\nreturn UpdatePosition"
    local position=assert(load(code,"@production-pettarget-position","t",e))("_FluxUI",ns,pt)
    check(position()and pt.actualHeight==77 and pt.actualWidth==41,"real pet target inherits known pet height and configured width")
    combat=true;check(position()==false and pt.needsPositionUpdate,"pet target defers protected position in combat");combat=false
    uf.ApplyEmulatedHorizontalSqueezeForFrame=oldSqueeze

    e.UIParent={GetEffectiveScale=function()return 1 end}
    local party=frame(250,100);party.PortraitFrame={SetShown=function()end}
    party._fluxPartyThreat={SetScale=function()end,ClearAllPoints=function()end,SetAllPoints=function()end}
    local partyPet=frame(40,40);partyPet.nameText={SetAlpha=function()end}
    local partyTarget={ClearAllPoints=function()end,SetPoint=function()end,SetSize=function(self,w,h)self.width,self.height=w,h end}
    ns.PartyFrames={GetSizing=function()return 284,112 end,StyleText=function()end}
    local layout=run("local _,ns=...;local UF,Party=ns.UnitFrames,ns.PartyFrames;local ApplyScale=function(f,v)f:SetScale(v)end;local LayoutTextHosts=function()end\n"
        ..slice(read("UnitFrames/FluxUnitFrames_Party.lua"),"local function LayoutVisuals(frame, pet, target, db, scale, petScale)","local function AnchorSlot(frame, index, dock, scale)").."\nreturn LayoutVisuals")
    layout(party,partyPet,partyTarget,{partyPowerHeightScale=.5},1,.8)
    check(party.actualWidth==284 and party.actualHeight==112 and party._fluxPartyPowerHeightScale==.5,"real party layout records owner dimensions before partition")
    check(partyTarget.width==30 and partyTarget.height==148,"party target public companion dimensions are preserved")

    -- Full options bridge supplies height and base width for every primary
    -- frame; the real squeeze writer records its final displayed width.
    e.UIParent={GetEffectiveScale=function()return 1 end};e.FLUX_API={hasFocusUnit=true}
    ns.PlayerFrame=f;e.FluxUnitFrames_ShouldUseFlux=function()return true end
    e.FluxUnitFrames_GetWholeFrameScale=function()return 1 end
    e.FluxUnitFrames_GetConfiguredFrameSize=function()return 320,86 end
    e.FluxUnitFrames_GetConfiguredPetTargetBarWidth=function()return 41 end
    local bridge=read("UnitFrames/FluxUnitFrames_OptionsBridge.lua")
    local bridgeStart=assert(bridge:find("function FluxUnitFrames_ApplyFrameSizesFromDB()",1,true))
    run("local _,ns=...\n"..bridge:sub(bridgeStart))
    e.FluxUnitFrames_ApplyFrameSizesFromDB()
    check(f.actualWidth==240 and f.actualHeight==86,"real options writer captures configured height plus squeezed width")
end
print(("Public geometry writers: %d checks; four clients; squeeze/focus/pet-target/party/options; native getters inaccessible"):format(checks))
