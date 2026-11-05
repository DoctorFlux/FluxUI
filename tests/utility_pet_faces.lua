-- Real utility assignment/manager/painter; native journal and secure frames mocked.
local source = arg[1] or "ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua"
local checks, failed = 0, 0
local function check(ok, msg) checks=checks+1; if not ok then failed=failed+1; print("FAIL "..msg) end end
for _, family in ipairs({"retail","forever","era","anniversary","mists","no-journal"}) do
 local state = { mod="", combat=false, timers={}, frames={}, tooltip=nil }
 local env=setmetatable({}, {__index=_G}); env._G=env
 env.GetTime=function() return 10 end; env.GetCursorInfo=function() return "battlepet","BattlePet-0-ABC",23 end
 env.InCombatLockdown=function() return state.combat end
 env.IsShiftKeyDown=function() return state.mod=="SHIFT" end; env.IsControlKeyDown=function() return false end; env.IsAltKeyDown=function() return false end
 env.C_Timer={After=function(_,fn) state.timers[#state.timers+1]=fn end}
 env.CreateFrame=function()
  local f={events={},scripts={}}
  function f:RegisterEvent(e) self.events[e]=true end
  function f:RegisterUnitEvent(e) self.events[e]=true end
  function f:SetScript(e,fn) self.scripts[e]=fn end
  state.frames[#state.frames+1]=f;return f
 end
 local modifier
 env.FluxModifierTracker={Register=function(_,fn) modifier=fn end}
 env.GetBindingKey=function() end
 if family~="no-journal" then
  env.C_PetJournal={GetPetInfoByPetID=function(id)
   if state.cold then return end
   return 1,id=="BattlePet-0-ABC" and "Custom pet" or nil,1,1,1,1,false,"Species",id=="BattlePet-0-ABC" and 101 or 202
  end,GetSummonedPetGUID=function() return "BattlePet-0-ABC" end}
 end
 local flux={EBS={Action={}},Client={isForever=family=="forever"}}
 env.Flux=flux;env.FluxButton={}
 local ns={Flux=flux}
 assert(loadfile("ExtraButtonSystem/Engine/Paint.lua","t",env))("_FluxUI",ns)
 assert(loadfile("ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua","t",env))("_FluxUI",ns)
 assert(loadfile(source,"t",env))()
 local a,m=env.FluxNCUtilitySlots,env.FluxNCUtilitySlotsManager
 local w={attrs={}}
 function w:SetAttribute(k,v) check(not state.combat,"no protected writes in combat");self.attrs[k]=v end
 function w:GetAttribute(k) return self.attrs[k] end
 local icon={SetTexture=function(_,v) state.icon=v end,Show=function() end,SetTexCoord=function() end,SetDesaturated=function() end,SetVertexColor=function() end}
 local btn={Widget=w,WIcon=icon,slotIndex=1}
 function btn:SetAction(t,v) check(not state.combat,"action writes outside combat");self.ActionType=t;self.ActionValue=v;self.MacroBody=v;self.MacroMode="" end
 function btn:ClearAction() self.ActionType=nil;self.ActionValue=nil end
 m.buttons[1]=btn
 a.Manager=nil;m.UpdateAllSlots=function() end
 local pending=state.timers;state.timers={};for _,fn in ipairs(pending) do fn() end
 a.Assign(1,{type="battlepet",id="BattlePet-0-ABC"},"")
 a.Assign(1,{type="battlepet",id="BattlePet-0-DEF"},"SHIFT")
 local slots=a.GetSlots()[1]
 m.UpdateButton(btn,slots)
 local body=btn.MacroBody
 check(body:find("/summonpet",1,true) and body:find("BattlePet-0-ABC",1,true),"native GUID summon macro retained")
 flux.EBS.Paint.UpdateIcon(btn)
 if env.C_PetJournal then
  check(a.ParseCursor().id=="BattlePet-0-ABC","journal cursor keeps the unique pet GUID")
  check(state.icon==101,family.." base pet icon")
  local tip={SetCompanionPet=function(_,id) state.tooltip=id end,SetText=function(_,v) state.tooltip=v end}
  if btn._fluxTooltipExtras then btn._fluxTooltipExtras(btn,tip) end
  check(state.tooltip=="BattlePet-0-ABC",family.." pet tooltip uses selected GUID")
  state.mod="SHIFT";state.combat=true
  modifier();flux.EBS.Paint.UpdateIcon(btn)
  check(state.icon==202,family.." modifier changes pet face during combat")
  check(btn.MacroBody==body,family.." modifier display does not rebuild action")
  state.mod="";modifier();flux.EBS.Paint.UpdateIcon(btn)
  check(state.icon==101,family.." modifier release restores pet")
  state.combat=false
  state.cold=true;m.UpdateButton(btn,slots)
  check(btn.IconOverrideTexture and btn.IconOverrideTexture~=134400,family.." cold metadata has a pet fallback")
  state.cold=false
  for _,frame in ipairs(state.frames) do
   if frame.events.PET_JOURNAL_LIST_UPDATE then frame.scripts.OnEvent(frame,"PET_JOURNAL_LIST_UPDATE") end
  end
  local pending=state.timers;state.timers={};for _,fn in ipairs(pending) do fn() end
  check(state.icon==101,family.." journal metadata event restores actual pet icon")
  local snapshot=a.CaptureSnapshot()
  a.ApplySnapshot(snapshot);m.UpdateButton(btn,a.GetSlots()[1])
  check(state.icon==101 and a.GetSlots()[1][""].id=="BattlePet-0-ABC",family.." snapshot reload preserves GUID and face")
  a.ClearModifier(1,"");m.UpdateButton(btn,a.GetSlots()[1])
  check(state.icon==202,family.." modifier-only pet mirrors onto base")
  a.Assign(1,{type="item",id=77},"");m.UpdateButton(btn,a.GetSlots()[1])
  check(btn.IconOverrideTexture==nil and btn._fluxTooltipExtras==nil,family.." replacing pet clears owned presentation")
 else check(not btn.IconOverrideTexture,"missing journal creates no invented pet icon") end
end
print(("Utility pet faces: %d checks, %d failures"):format(checks,failed));os.exit(failed>0 and 1 or 0)
