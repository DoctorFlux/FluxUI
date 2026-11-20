-- Actual full UpdateOuterBorder control flow; unrelated painters are modeled.
local sourcePath=arg[1] or 'UnitFrames/FluxUnitFrames_Shared.lua';local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local checks=0;local function check(v,m)checks=checks+1;assert(v,m)end
local private=setmetatable({},{__eq=function()error('private equality')end})
local function secret(v)return rawequal(v,private)end
local function public(v)if secret(v)or type(v)~='number'or v~=v or v==math.huge or v==-math.huge then return nil end;return v end
local function fixture(path)
 local source=read(path);local a=assert(source:find('function UF.UpdateOuterBorder(',1,true));local b=assert(source:find('-- Additional Power Bar (Druid Mana, etc)',a,true));local body=source:sub(a,b-1)
 local h=source:find('local function OuterBorderGeometryMatches',1,true);if h then body=source:sub(h,a-1)..body end
 local state={combat=false,writes=0,colors=0,tail=0,registered=false};local UF={}
 local function noop()end
 for _,name in ipairs{'PrepareClassIconBounds','UpdateAuraPosition','LayoutBigDebuffsCornerPlaceholder','LayoutPetHappinessIcon','LayoutRaidMarker','UpdateRaidMarker','UpdatePvpBadge'}do UF[name]=noop end
 UF.FrameUsesPortraitLayout=function()return false end
 UF.UpdateBorderColors=function()state.colors=state.colors+1;state.callTail=0;if state.failure=='paint'then error('paint failed')end end
 local env=setmetatable({UF=UF,ns={},PublicGeometryNumber=public,ValueIsSecret=secret,IsFluxUnitFrame=function()return true end,InCombatLockdown=function()return state.combat end,
 LayoutNameStripLevelText=noop,LayoutNameStripStatusAndPvpIcons=noop,LayoutNameStripCombatIcon=function()state.tail=state.tail+1;state.callTail=state.callTail+1;if state.callTail==2 then if state.failure=='tail'then error('tail failed')end;if state.reenter~=nil then state.combat=state.reenter end end end},{__index=_G})
 assert(load(body,'@actual-full-outer-lifecycle','t',env))()
 local f={unit='pet',GetWidth=function()return 88 end,GetHeight=function()return 45 end,
 IsEventRegistered=function()return state.registered end,RegisterEvent=function()state.registered=true end}
 local o={points={},width=0,height=0}
 function o:GetSize()if state.privateGetter then return private,private end;return self.width,self.height end
 function o:GetNumPoints()return #self.points end
 function o:GetPoint(i)return table.unpack(self.points[i])end
 function o:ClearAllPoints()check(not state.combat,'no combat geometry writes');state.writes=state.writes+1;self.points={}end
 function o:SetSize(w,h)check(not state.combat,'no combat geometry writes');state.writes=state.writes+1;if state.failure=='native'then error('SetSize failed')end;self.width,self.height=w,h end
 function o:SetPoint(...)check(not state.combat,'no combat geometry writes');state.writes=state.writes+1;self.points[#self.points+1]={...}end
 f.outerBorderFrame=o
 return UF,f,state
end
local function run(path,expectComplete)
 local UF,f,s=fixture(path)
 s.combat=true;UF.UpdateOuterBorder(f);check(f.needsOuterBorderUpdate==true and s.writes==0,'combat entry retains pending outer work and skips geometry');check(s.registered,'combat deferred flag preserves regen registration')
 s.combat=false;UF.UpdateOuterBorder(f);check((f.needsOuterBorderUpdate==nil)==expectComplete,'successful full OOC completion clears outer flag only in candidate');check(s.writes==3 and s.tail==4,'full source geometry and both status passes per call completed')
 if not expectComplete then return end
 f.needsOuterBorderUpdate=true;f.needsPartitionRelayout=true;UF.UpdateOuterBorder(f);check(f.needsOuterBorderUpdate==nil and f.needsPartitionRelayout==true,'completed outer work never consumes separate partition work')
 for _,failure in ipairs{'paint','tail','native'}do
  f.needsOuterBorderUpdate=true;s.failure=failure;if failure=='native'then f.outerBorderFrame.width=0;s.privateGetter=true end
  local ok,err=pcall(UF.UpdateOuterBorder,f);check(not ok and tostring(err):find('failed',1,true),'production exception remains visible');check(f.needsOuterBorderUpdate==true,'exception/failing private-read fallback cannot clear pending work');s.failure=nil;s.privateGetter=false
 end
 for _,reenter in ipairs{true,private}do
  f.needsOuterBorderUpdate=true;s.combat=false;s.reenter=reenter;UF.UpdateOuterBorder(f);check(f.needsOuterBorderUpdate==true,'reentrant/private lockdown at final consumer retains pending work');s.reenter=nil;s.combat=false
 end
 -- Geometry was skipped because the call began in combat, even though the last
 -- modeled paint consumer observes an unlocked state before return.
 f.needsOuterBorderUpdate=true;s.combat=true;s.reenter=false;local old=s.writes;UF.UpdateOuterBorder(f);check(f.needsOuterBorderUpdate==true and s.writes==old,'entry-combat cannot falsely complete after mid-call unlock');s.reenter=nil;s.combat=false
 UF.UpdateOuterBorder(f);check(f.needsOuterBorderUpdate==nil,'later complete OOC recovery clears flag')
end
run(sourcePath,true)
print('PASS actual full Outer completion lifecycle '..checks..' checks; paint/aura helpers modeled; no native combat-safety claim')
