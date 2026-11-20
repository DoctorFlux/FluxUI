-- Actual stance chrome + Anchor and actual player portrait/outer producers.
-- Check the background endpoints, not merely whether a border mesh exists.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local init=read(arg[1]or'Bars/Stance/Init.lua')
local a=assert(init:find('Stance.STANCE_SIZE =',1,true))
local constants=init:sub(a,assert(init:find('local frame',a,true))-1)
a=assert(init:find('function Stance.ApplyBorderChrome()',1,true))
local chrome=init:sub(a,assert(init:find('-- SHAPESHIFTBUTTON',a,true))-1)
local layout=read('Bars/Stance/Layout.lua')
local script=read('tests/unit_portrait_border_fit.lua')
script=script:gsub('CENTER={%.5,%.5}}','CENTER={.5,.5},LEFT={0,.5},RIGHT={1,.5},TOP={.5,1},BOTTOM={.5,0}}',1)
local checks,scenes=0,0
local function check(v,m)checks=checks+1;assert(v,m)end
local function near(a,b)return math.abs(a-b)<1e-7 end
local function probe(player,pf,B,state,new,e,counts)
 scenes=scenes+1
 local attached=true
 local stance={ShouldAnchorToPlayerBorder=function()return attached end}
 local frame=new(e.UIParent);frame:SetSize(50,select(4,player.outerBorderFrame:GetRect()))
 local m=getmetatable(frame).__index
 -- Native SetPoint replaces the named anchor. The older constructor fixture
 -- only appended anchors and therefore retained the superseded backdrop edge.
 local setPoint=m.SetPoint
 function m:SetPoint(point,...)
  for i=#self.points,1,-1 do if self.points[i][1]==point then table.remove(self.points,i)end end
  return setPoint(self,point,...)
 end
 function m:GetScale()return self.scale or 1 end
 function m:SetScale(v)check(not state.locked,'stance scale remains outside lockdown');self.scale=v end
 e.Stance=stance;e.FluxBorder=B
 e.InLockdown=function()return state.locked end
 assert(load('local frame,lastBorderMode=...\n'..constants..chrome,'@actual-stance-chrome','t',e))(frame)
 stance.GetFrame=function()return frame end
 e.Flux.Bars={Stance=stance};e.Flux.Combat={InLockdown=e.InLockdown,Defer=function()end}
 local ns={Flux=e.Flux,PlayerFrame=player}
 assert(load(layout,'@actual-stance-anchor','t',e))('_FluxUI',ns)
 stance.Anchor()
 local bg=frame.FluxBorderFrame.BackgroundFrame
 local x,y,w,h=bg:GetRect();local ox=player.outerBorderFrame:GetRect()
 local rootX,rootY,rootW,rootH=frame:GetRect()
 check(near(x+w,ox),'attached stance backdrop meets player frame without uncovered vertical strip')
 check(near(x,rootX+stance.BORDER_PAD_H),'stance outside left inset remains unchanged')
 check(near(y,rootY+stance.BORDER_PAD_V)and near(h,rootH-2*stance.BORDER_PAD_V),'stance rounded top and bottom exclusions remain unchanged')
 check(near(frame:GetEffectiveScale(),player:GetEffectiveScale()),'actual stance anchor keeps player scale')
 local before,writes=counts();local clears,levels=state.clears,state.levels
 state.locked=true
 for _=1,50 do stance.ApplyBorderChrome()end
 state.locked=false
 for _=1,50 do stance.ApplyBorderChrome()end
 local after,afterWrites=counts()
 check(after==before and afterWrites==writes and state.clears==clears and state.levels==levels,'warm/combat chrome performs no allocation or geometry write')
 attached=false;stance.ApplyBorderChrome()
 local detached=frame.FluxBorderFrame.BackgroundFrame
 local dx,dy,dw,dh=detached:GetRect()
 check(near(dx,rootX+stance.PET_SLOT_FLUX_PAD_H)and near(dx+dw,rootX+rootW-stance.PET_SLOT_FLUX_PAD_H),'detaching restores original symmetric backdrop insets')
 attached=true;stance.ApplyBorderChrome()
 local rx,_,rw=frame.FluxBorderFrame.BackgroundFrame:GetRect()
 check(near(rx+rw,ox),'reattaching restores the shared backdrop endpoint')
end
local marker='local bf=pf.FluxBorderFrame;local tracks=b:GetJoinTracks()'
local at=assert(script:find(marker,1,true))
script=script:sub(1,at+#marker-1)..'\nProbeStanceBackdrop(frame,pf,b, state,new,e,counts)\n'..script:sub(at+#marker)
local env=setmetatable({ProbeStanceBackdrop=probe,arg={}},{__index=_G});env._G=env
assert(load(script,'@actual-portrait-with-stance-contact','t',env))()
print('Stance/portrait backdrop: '..checks..' checks /'..scenes..' actual scenes PASS; source chrome and anchor; attach/detach; unchanged corners/roots; warm combat static; native pixels/taint/FPS pending')
