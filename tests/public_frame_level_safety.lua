-- Exact current helpers + complete portrait/threat layering consumers. Opaque
-- arithmetic traps establish a conditional contract failure, not native reach.
local file=assert(io.open("UnitFrames/FluxUnitFrames_Shared.lua","rb"));local source=file:read("*a"):gsub("\r\n","\n");file:close()
local function cut(a,b)local p=assert(source:find(a,1,true),a);return source:sub(p,assert(source:find(b,p+#a,true),b)-1)end
local checks=0;local function check(v,why)checks=checks+1;assert(v,why)end
local function boot()
    local s={traps=0,unitCombat=false,sets=0};local function denied()s.traps=s.traps+1;error("OPAQUE_FRAME_LEVEL_ARITHMETIC")end
    s.opaque=setmetatable({},{__add=denied,__sub=denied,__lt=denied,__le=denied})
    local uf={};local api={IsSecretValue=function(v)return v==s.opaque end,CanAccessValue=function()return true end,
        SafeBooleanTest=function(v,d)return type(v)=="boolean"and v or d end}
    local e=setmetatable({},{__index=_G});e._G=e
    e.InCombatLockdown=function()return false end;e.UnitExists=function()return true end;e.UnitAffectingCombat=function()return s.unitCombat end
    local function noop()end
    local ns={UnitFrames=uf,API=api,Border={SetBorderColor=noop,SetBackdropColor=noop,SetClassColor=noop}}
    local chunk="local _,ns=...;local UF,API=ns.UnitFrames,ns.API\n"
        ..cut("local function ValueIsSecret(value)","local function PlayerDeadOrGhost(unit)")
        ..cut("local function SafeBooleanTest(value, default)","local function SafeCompareGUID(guid1, guid2)")
        ..cut("local PORTRAIT_COMBAT_BORDER_R","function UF.UpdateBorderColors(self)")
        ..cut("local function ThreatBarRaiseGlowAboveBorder(shell)","local function RetireLegacyThreatOverlay(overlay)")
        .."\nreturn ThreatBarRaiseGlowAboveBorder"
    local raise=assert(load(chunk,"@production-frame-level-consumers","t",e))("_FluxUI",ns)
    local function region(level)
        return {level=level,GetFrameLevel=function(self)return self.level end,SetFrameLevel=function(self,v)self.level=v;s.sets=s.sets+1 end,
            Hide=noop,Show=noop,SetVertexColor=noop}
    end
    local pf=region(41);pf.FluxBorderFrame=region(51);pf.bg=region(0)
    local root=region(40);root.unit="player";root.PortraitFrame=pf;root.outerBorderFrame={FluxBorderFrame=region(60)}
    local shell=region(40);shell.FluxBorderFrame=region(50);shell._fluxThreatButtonGlow=region(0);shell.TextFrame=region(0)
    s.uf,s.raise,s.root,s.shell,s.region=uf,raise,root,shell,region;return s
end

do
    local s=boot();s.unitCombat=true;s.uf.UpdatePortraitCombatTint(s.root)
    check(s.root.PortraitFrame.FluxBorderFrame.level==62,"public combat border level remains outer+2")
    s.unitCombat=false;s.uf.UpdatePortraitCombatTint(s.root)
    check(s.root.PortraitFrame.FluxBorderFrame.level==51,"public normal border remains portrait+10")
    s.root.PortraitFrame.level=s.opaque
    check(pcall(s.uf.UpdatePortraitCombatTint,s.root),"private portrait getter retains permitted level without arithmetic")
    s.unitCombat=true;s.root.outerBorderFrame.FluxBorderFrame.level=s.opaque
    check(pcall(s.uf.UpdatePortraitCombatTint,s.root),"private outer border uses last permitted public level")
    s.root.outerBorderFrame=nil;s.root.level=s.opaque
    check(pcall(s.uf.UpdatePortraitCombatTint,s.root),"private root retains known public fallback")
    check(s.traps==0,"all prior conditional arithmetic-denial paths now avoid opaque operations")
end
do
    local s=boot();local root,pf=s.root,s.root.PortraitFrame
    root._fluxPublicFrameLevel=40;root.level=s.opaque;pf.level=s.opaque
    s.uf.RecordRelativeFramePublicLevel(pf,root,1)
    check(s.uf.GetFramePublicLevel(pf)==41,"owned first-paint relation resolves an inaccessible child")
    s.uf.SetFramePublicLevel(root,70)
    check(s.uf.GetFramePublicLevel(pf)==71,"parent move preserves known relative level instead of stale child cache")
    s.unitCombat=false;s.uf.UpdatePortraitCombatTint(root)
    check(pf.FluxBorderFrame.level==81,"normal portrait priority follows public parent move")
    local shell=s.shell;shell.level=s.opaque;shell._fluxPublicFrameLevel=50;shell.FluxBorderFrame.level=s.opaque
    s.uf.RecordRelativeFramePublicLevel(shell.FluxBorderFrame,shell,10)
    s.raise(shell);check(shell._fluxThreatButtonGlow.level==65 and shell.TextFrame.level==70,"private border/root retains exact threat priorities")
    s.uf.SetFramePublicLevel(shell,80);s.raise(shell)
    check(shell._fluxThreatButtonGlow.level==95 and shell.TextFrame.level==100,"private threat layering follows moved public owner")
    shell.FluxBorderFrame=nil;shell._fluxPublicFrameLevel=nil
    local oldGlow,oldText=shell._fluxThreatButtonGlow.level,shell.TextFrame.level
    s.raise(shell)
    check(shell._fluxThreatButtonGlow.level==oldGlow and shell.TextFrame.level==oldText,"unknown external owner changes no art/visibility/priority")
    check(s.traps==0,"known relations and unknown controls do not inspect opaque levels")
end
print("Public frame-level safety: "..checks.." checks; actual portrait/private threat consumers, first private geometry/parent moves/unknown preservation")

