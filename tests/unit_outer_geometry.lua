-- Production geometry-stage replay; no native rendering/FPS/taint claim.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local checks=0;local function check(v,m)checks=checks+1;assert(v,m)end
local opaque=setmetatable({private=true,id='private'},{__eq=function()error('private equality')end,__sub=function()error('private arithmetic')end})
local function secret(v)return rawequal(v,opaque)or(type(v)=='table'and rawget(v,'private')==true)end
local function public(v)if secret(v) or type(v)~='number' or v~=v or v==math.huge or v==-math.huge then return nil end;return v end
local function build(s)
 local a=assert(s:find('    -- Layout Updates (Protected during combat)',assert(s:find('function UF.UpdateOuterBorder(',1,true)),true));local b=assert(s:find('    -- Update custom vehicle exit button position',a,true))
 local helpers='';local h=s:find('local function OuterBorderGeometryMatches',1,true);if h then helpers=s:sub(h,assert(s:find('function UF.UpdateOuterBorder(',h,true))-1)end
 local env=setmetatable({PublicGeometryNumber=public,ValueIsSecret=secret,UF={}},{__index=_G})
 env.UF.UpdateAuraPosition=function(f)f.calls.aura=f.calls.aura+1 end;env.UF.LayoutBigDebuffsCornerPlaceholder=function(f)f.calls.placeholder=f.calls.placeholder+1 end
 local chunk=helpers..'return function(self,inCombat,totalWidth,totalHeight,hasPortrait,portraitPosition,portraitSize,outerBorderAlignment,outerBorderPadding,totPos2Minimal)\n'..s:sub(a,b-1)..'end'
 return assert(load(chunk,'@actual-outer-geometry-stage','t',env))(),s
end
-- Archived exact pre-guard production geometry stage; it is the comparison
-- implementation, not a duplicate of the new guard. Native pixels remain pending.
local referenceSource=[=[
function UF.UpdateOuterBorder(self)
    -- Layout Updates (Protected during combat)
    if not inCombat then
        self.outerBorderFrame:ClearAllPoints()

        if hasPortrait then
            -- Same width as atlas border, but + outerBorderPadding taller
            local combinedWidth = totalWidth + portraitSize -- unit frame + portrait + small gap
            local combinedHeight = totalHeight + outerBorderPadding -- Configurable height

            self.outerBorderFrame:SetSize(combinedWidth, combinedHeight)

            local verticalOffset
            if outerBorderAlignment == "BOTTOM" then
                -- Align bottom with atlas border bottom (outer extends upward)
                verticalOffset = outerBorderPadding -- Align bottoms
            else -- "TOP"
                -- Align top with atlas border top (outer extends downward)
                verticalOffset = 0 -- Same top alignment as atlas border
            end

            if portraitPosition == "LEFT" then
                self.outerBorderFrame:SetPoint("TOPLEFT", self.PortraitFrame, "TOPLEFT", 0, verticalOffset)
            else -- RIGHT
                self.outerBorderFrame:SetPoint("TOPLEFT", self, "TOPLEFT", 0, verticalOffset)
            end
        else
            -- No portrait, outer border just encompasses the unit frame
            self.outerBorderFrame:SetSize(totalWidth, totalHeight + outerBorderPadding)

            local verticalOffset
            if outerBorderAlignment == "BOTTOM" then
                verticalOffset = outerBorderPadding -- Align bottom with atlas border
            else -- "TOP"
                verticalOffset = -2 -- Align top with atlas border
            end

            -- Default -2 pulls the border left of the frame; bars stay on the frame so content
            -- looks shifted right inside the border. ToT: align X with frame for even chrome.
            local outerX = (self.unit == "targettarget" or self.unit == "focustarget") and 0 or -2
            self.outerBorderFrame:SetPoint("TOPLEFT", self, "TOPLEFT", outerX, verticalOffset)
        end

        if self.mouseoverHighlight and self.mouseoverHighlight._fluxLayoutMouseover then
            self.mouseoverHighlight._fluxLayoutMouseover()
        end

        -- Flux auras anchor to outerBorderFrame; refresh after border size/position is final.
        if not totPos2Minimal then
            if UF.UpdateAuraPosition then
                UF.UpdateAuraPosition(self)
            end
            UF.LayoutBigDebuffsCornerPlaceholder(self)
        end
    end

    -- Update custom vehicle exit button position
end
]=]
local before=build(referenceSource);local after,candidate=build(read(arg[1] or 'UnitFrames/FluxUnitFrames_Shared.lua'))
local function f32(v)return string.unpack('f',string.pack('f',v))end
local function frame(unit,quant)
 local calls={writes=0,sizeReads=0,countReads=0,pointReads=0,aura=0,placeholder=0,mouse=0,order={}}
 local f={unit=unit,id='self',calls=calls,PortraitFrame={id='portrait'}};local o={id='outer',width=0,height=0,points={},f=f,quant=quant}
 local function write(s,name)check(not s.locked,'no protected write while combat locked');s.f.calls.writes=s.f.calls.writes+1;s.f.calls.order[#s.f.calls.order+1]=name;if s.setterError==name then error('native '..name..' denied')end end
 function o:ClearAllPoints()write(self,'ClearAllPoints');self.points={};if self.implicit then self.width,self.height=0,0;self.implicit=false end end
 function o:SetSize(w,h)write(self,'SetSize');self.width,self.height=self.quant and f32(w) or w,self.quant and f32(h) or h end
 function o:SetPoint(p,owner,rp,x,y)write(self,'SetPoint');self.points[#self.points+1]={p,owner,rp,x,y}end
 function o:GetSize()calls.sizeReads=calls.sizeReads+1;if self.getterError=='GetSize'then error('GetSize denied')end;if self.privateSize then return opaque,opaque end;return self.width,self.height end
 function o:GetNumPoints()calls.countReads=calls.countReads+1;if self.getterError=='GetNumPoints'then error('GetNumPoints denied')end;if self.privateCount then return opaque end;return #self.points end
 function o:GetPoint(i)calls.pointReads=calls.pointReads+1;if self.getterError=='GetPoint'then error('GetPoint denied')end;local p=self.points[i];if self.privatePoint then return opaque,opaque,opaque,opaque,opaque end;if self.privateOwner then return p[1],opaque,p[3],p[4],p[5]end;return table.unpack(p)end
 f.outerBorderFrame=o;f.mouseoverHighlight={_fluxLayoutMouseover=function()calls.mouse=calls.mouse+1 end};return f
end
local function reset(f)local c=f.calls;for k,v in pairs(c)do if type(v)=='number'then c[k]=0 end end;c.order={}end
local function snap(f)local o=f.outerBorderFrame;local p={o.width,o.height};for _,v in ipairs(o.points)do p[#p+1]=table.concat({v[1],v[2].id,v[3],string.format('%.17g',v[4]),string.format('%.17g',v[5])},':')end;return table.concat(p,'|')end
local function run(fn,f,v,combat)f.outerBorderFrame.locked=combat;return fn(f,combat,v.w,v.h,v.portrait,v.side,v.ps,v.align,v.pad,v.minimal)end
local rows={};local cases=0
for _,unit in ipairs{'player','target','focus','pet','targettarget','focustarget','party1','partypet1'}do
 for _,style in ipairs{1,2}do for _,scale in ipairs{.5,.75,1,1.25,2.5}do
 for _,portrait in ipairs{false,true}do for _,side in ipairs{'LEFT','RIGHT'}do for _,align in ipairs{'TOP','BOTTOM'}do
  cases=cases+1;local v={w=237.59356689453,h=88,portrait=portrait,side=side,ps=88,align=align,pad=36,minimal=false};local a,b=frame(unit,true),frame(unit,true)
  run(before,a,v,false);run(after,b,v,false);check(snap(a)==snap(b),'cold shape parity');check(a.calls.writes==3 and b.calls.writes==3,'cold layout retains original three setters');check(table.concat(b.calls.order,',')=='ClearAllPoints,SetSize,SetPoint','cold setter order')
  reset(a);reset(b);for _=1,10 do run(before,a,v,false);run(after,b,v,false)end
  check(snap(a)==snap(b),'quantized settled geometry parity');check(a.calls.writes==30 and b.calls.writes==0,'steady shell write reduction');check(b.calls.sizeReads==10 and b.calls.countReads==10 and b.calls.pointReads==10,'fresh three-query guard each time');check(a.calls.aura==b.calls.aura and a.calls.placeholder==b.calls.placeholder and a.calls.mouse==b.calls.mouse,'callbacks remain unchanged')
  local item={unit=unit,style=style,scale=scale,portrait=portrait,side=side,align=align,baselineWrites=a.calls.writes,candidateWrites=b.calls.writes};rows[#rows+1]=item
  for _,drift in ipairs{1/64,1/scale}do
   for _,kind in ipairs{'size','offset','relative','multi'}do
    local function alter(f)local o=f.outerBorderFrame;if kind=='size'then o.width=o.width+drift elseif kind=='offset'then o.points[1][4]=o.points[1][4]+drift elseif kind=='relative'then o.points[1][2]={id='wrong'}else o.points[2]={'BOTTOMRIGHT',{id='other'},'BOTTOMRIGHT',0,0};o.implicit=true end end
    alter(a);alter(b);reset(a);reset(b);run(before,a,v,false);run(after,b,v,false);check(snap(a)==snap(b),'changed native geometry repaired exactly');check(b.calls.writes==3,'pixel/1/64/anchor/multi-point drift uses original writes');check(table.concat(b.calls.order,',')=='ClearAllPoints,SetSize,SetPoint','repair keeps complete original sequence')
   end
  end
  v.w=v.w+1;v.ps=72;v.pad=18;v.side=side=='LEFT'and'RIGHT'or'LEFT';v.align=align=='TOP'and'BOTTOM'or'TOP';reset(a);reset(b);run(before,a,v,false);run(after,b,v,false);check(snap(a)==snap(b)and b.calls.writes==3,'settings change repairs actual geometry')
  reset(a);reset(b);run(before,a,v,true);run(after,b,v,true);check(a.calls.writes==0 and b.calls.writes==0 and b.calls.sizeReads==0 and b.calls.pointReads==0,'combat skips getters and protected setters');check(a.calls.aura==0 and b.calls.aura==0,'combat callbacks retain original suppression')
 end end end end end
end
local v={w=237.59356689453,h=88,portrait=true,side='RIGHT',ps=88,align='BOTTOM',pad=36,minimal=false}
for _,mode in ipairs{'GetSize','GetNumPoints','GetPoint','privateSize','privateCount','privatePoint','privateOwner','privateBorder','privateSizeMethod','privateCountMethod','privatePointMethod','missingSize','missingCount','missingPoint'}do
 local a,b=frame('target',false),frame('target',false);run(before,a,v,false);run(after,b,v,false)
 for _,f in ipairs{a,b}do local o=f.outerBorderFrame;if mode=='privateBorder'then o.private=true elseif mode=='privateSizeMethod'then o.GetSize=opaque elseif mode=='privateCountMethod'then o.GetNumPoints=opaque elseif mode=='privatePointMethod'then o.GetPoint=opaque elseif mode:sub(1,7)=='private'then o[mode]=true elseif mode=='missingSize'then o.GetSize=nil elseif mode=='missingCount'then o.GetNumPoints=nil elseif mode=='missingPoint'then o.GetPoint=nil else o.getterError=mode end;reset(f)end
 local okA=pcall(run,before,a,v,false);local okB=pcall(run,after,b,v,false);check(okA and okB and snap(a)==snap(b),'getter/privacy failure falls back without secret inspection');check(b.calls.writes==3,'unknown/current missing native fields keep original setters')
end
-- The desired anchor also passes the privacy gate before pointer comparison.
do local a,b=frame('player',false),frame('player',false);local pv={w=v.w,h=v.h,portrait=true,side='LEFT',ps=v.ps,align=v.align,pad=v.pad,minimal=false};a.PortraitFrame,b.PortraitFrame=opaque,opaque;run(before,a,pv,false);run(after,b,pv,false);check(snap(a)==snap(b)and b.calls.writes==3,'private expected anchor falls through original setters without pointer comparison')end
-- A real current-state correction is observed fresh, including after method replacement.
do local a,b=frame('target',false),frame('target',false);run(before,a,v,false);run(after,b,v,false);local old=b.outerBorderFrame.GetSize;b.outerBorderFrame.GetSize=function(s)local w,h=old(s);return w+1/64,h end;reset(b);run(after,b,v,false);check(b.calls.writes==3,'changed native getter cannot use an old method/value stamp')end
-- No partial fast path: an implicit multi-anchor width must be explicitly restored after Clear.
do local b=frame('focus',false);run(after,b,v,false);b.outerBorderFrame.points[2]={'BOTTOMRIGHT',b,'BOTTOMRIGHT',0,0};b.outerBorderFrame.implicit=true;reset(b);run(after,b,v,false);check(b.outerBorderFrame.width==v.w+v.ps and b.calls.writes==3,'multi-anchor repair cannot lose explicit dimensions')end
-- Original setter failure remains visible; guard does not hide a changed-state native error.
do local a,b=frame('party1',false),frame('party1',false);for _,f in ipairs{a,b}do f.outerBorderFrame.setterError='SetSize'end;local oka,era=pcall(run,before,a,v,false);local okb,erb=pcall(run,after,b,v,false);check(not oka and not okb and tostring(era):find('SetSize denied',1,true)and tostring(erb):find('SetSize denied',1,true),'native setter failures retain original error path')end
-- Minimal related-frame mode still skips aura/placeholder while retaining mouseover layout.
do local a,b=frame('targettarget',true),frame('targettarget',true);v.minimal=true;run(before,a,v,false);run(after,b,v,false);check(a.calls.aura==0 and b.calls.aura==0 and a.calls.mouse==1 and b.calls.mouse==1,'minimal mode callback parity')end
print('PASS unit outer geometry '..checks..' checks '..cases..' production-stage shapes; baseline steady 30 writes -> candidate0 +30 native reads per ten calls; native performance and pixels pending')
