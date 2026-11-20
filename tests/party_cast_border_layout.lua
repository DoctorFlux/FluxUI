-- Actual Party wrapper + actual shared cast layout. Cold setup and both direct
-- layout entry routes must stop before any protected setter during combat.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local src=read('tests/castbar_school_themes.lua')
src=src:sub(1,assert(src:find('local function checkParticleGeometry',1,true))-1)
src=src:gsub('pet="PetFrame"','pet="PetFrame",party1="PartyFrame"')
local fixture=assert(load(src..'\nreturn fixture','@actual-party-cast-fixture','t',_G))()
local party=read(arg[1]or'UnitFrames/FluxUnitFrames_Party.lua')
local function section(a,b)local first=assert(party:find(a,1,true));return party:sub(first,assert(party:find(b,first+#a,true))-1)end
local code=section('local function Secret(value)','function Party.GetStatusText')
 ..section('function Party.SyncCastCover(frame)','function Party.SetThreatColor')
 ..section('function Party.SetupCompactCastOverlay(frame)','local function PaintTarget')
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
for _,client in ipairs{'live','forever','classic','classic_era','classic_anniversary'}do
 local s,e,ns=fixture(client);local locked=false;local jobs={};local deferCalls=0
 e.InCombatLockdown=function()return locked end
 ns.UnitFrames.DeferProtected=function(key,fn)deferCalls=deferCalls+1;jobs[key]=fn end
 local bar=s.NewBar('party1');local frame=bar:GetParent()
 frame._fluxPartyMember=true;frame._fluxPartyClassChrome=true
 frame.outerBorderPadding=36;frame.outerBorderAlignment='BOTTOM'
 frame.atlasBorderFrame=e.CreateFrame('Frame',nil,frame);frame.atlasBorderFrame:SetSize(304,88)
 frame.outerBorderFrame=e.CreateFrame('Frame',nil,frame);frame.outerBorderFrame:SetSize(300,124)
 frame.nameText=frame:CreateFontString();frame.nameText:SetAlpha(.65)
 frame.levelText=frame:CreateFontString();frame.levelText:SetAlpha(.4)
 local methods=getmetatable(bar).__index
 function methods:GetNumPoints()return #self.points end
 function methods:GetPoint(i)local p=self.points[i];if p then return table.unpack(p)end end
 local P={members={frame}};ns.PartyFrames=P;e.Party=P;e.UF=ns.UnitFrames;e.ns=ns
 assert(load(code,'@actual-party-cast-owner','t',e))()
 bar:UpdateLayout()
 local writes=0
 for _,list in ipairs{s.frames,s.textures}do for _,object in ipairs(list)do
  for _,method in ipairs{'SetFrameLevel','SetPoint','ClearAllPoints','SetAllPoints','SetWidth','SetHeight','SetSize','HookScript'}do
   local original=object[method]
   if original then object[method]=function(self,...)
    check(not locked,'no protected geometry/script setter before Party cast combat guard: '..method)
    writes=writes+1;return original(self,...)
   end end
  end
 end end
 -- Real metadata/functions with cold Setup, not merely a standalone shared bar.
 locked=true;local before=writes
 for _=1,100 do P.SetupCompactCastOverlay(frame);P.LayoutCastOverlay(frame)end
 check(writes==before and deferCalls==1,'cold setup + direct overlay coalesce into one existing protected defer without native setters')
 locked=false;local pending=jobs;jobs={};for _,fn in pairs(pending)do fn()end
 check(bar._fluxCompactOverlay and bar:GetFrameLevel()==frame:GetFrameLevel()+110,'deferred setup installs real wrapper and correct raised party layer')
 check(bar:GetNumPoints()==2 and bar.IconFrame:GetNumPoints()==1,'completed party overlay records the exact header/adjacent-icon anchors')
 bar:Show();P.LayoutCastOverlay(frame)
 check(frame.nameText:GetAlpha()==0 and frame.levelText:GetAlpha()==0,'actual native-alpha cover path hides lower name/level while cast is visible')
 before=writes;local frameCount,textureCount=#s.frames,#s.textures
 for _=1,100 do bar:UpdateLayout();P.LayoutCastOverlay(frame)end
 check(writes==before and #s.frames==frameCount and #s.textures==textureCount,'100 actual wrapper/direct unchanged calls write no geometry or levels and allocate no graphic resources')
 check(frame.nameText:GetAlpha()==0 and frame.levelText:GetAlpha()==0,'cached layout still maintains actual label alpha policy')
 -- A changed shared-layout record or header must complete once, then stay static.
 frame.outerBorderFrame.width=320
 bar:UpdateLayout();check(writes>before,'actual header width change updates shared layout and party overlay')
 before=writes;bar:UpdateLayout();P.LayoutCastOverlay(frame)
 check(writes==before,'new completed shared layout/anchors are cached')
 bar:ClearAllPoints();bar:SetPoint('CENTER',e.UIParent,'CENTER',5,0)
 before=writes;P.LayoutCastOverlay(frame)
 check(writes>before and bar:GetNumPoints()==2,'real anchor changes are repaired even when dimensions and prepared-layout identity are unchanged')
 before=writes;P.LayoutCastOverlay(frame);check(writes==before,'repaired anchors immediately become static again')
 locked=true;frame.outerBorderFrame.width=340;local requests=deferCalls;before=writes
 for _=1,100 do bar:UpdateLayout();P.LayoutCastOverlay(frame)end
 check(writes==before and deferCalls==requests+1,'wrapped and direct reflow routes share one combat deferral before every setter')
 locked=false;pending=jobs;jobs={};for _,fn in pairs(pending)do fn()end
 check(writes>before and not bar._fluxPartyCastLayoutDeferred,'deferred real shared/party reflow completes after combat')
 before=writes;for _=1,100 do bar:UpdateLayout();P.LayoutCastOverlay(frame)end
 check(writes==before,'post-combat geometry is static after one completed layout')
 local header=frame.outerBorderFrame
 frame.outerBorderFrame=e.CreateFrame('Frame',nil,frame);frame.outerBorderFrame:SetSize(340,124)
 bar:UpdateLayout();local point,relative=bar.IconFrame:GetPoint(1)
 check(point=='TOPLEFT'and relative==frame.outerBorderFrame and relative~=header,'actual new header identity updates the completed anchor owner')
 bar:Hide()
 check(frame.nameText:GetAlpha()==.65 and frame.levelText:GetAlpha()==.4,'native OnHide restores the exact prior public label opacity')
end
print('Party cast border layout: '..checks..' checks PASS; actual shared layout plus real Party wrapper/direct overlay; cold and live combat guards; one deferred job; unchanged100calls zero native geometry/level/script writes; real shared/header/anchor changes; exact name/level alpha restoration. Native pixels/taint/FPS pending')
