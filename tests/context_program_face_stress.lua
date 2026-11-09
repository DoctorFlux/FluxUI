-- Real Context -> indexed ProgramFace -> Action.TranslateMacro, unchanged slot.
-- Native conditional parsing/rendering are boundary models; no secure writes.
local function read(path)local f=assert(io.open(path,"rb"));local s=f:read("*a");f:close();return(s:gsub("\r\n","\n"))end
local text=read("tests/context_invalidation_stress.lua")
text=text:sub(1,assert(text:find("for _, branch in ipairs(",1,true))-1)
text=text:gsub("return s, flux, notice","return s, flux, notice, e")
if arg[1]then text=text:gsub('read%("Core/Engine/Context.lua"%)','read("'..arg[1]:gsub('\\','/')..'/Core/Engine/Context.lua")')end
local boot=assert(load(text.."\nreturn fixture","@context-fixture","t",_G))()
local checks,failures=0,0
local function check(ok,label)checks=checks+1;if not ok then failures=failures+1;if failures<12 then print("FAIL "..label)end end end
local masks={"","s","c","sc","a","sa","ca","sca"}
for _,client in ipairs({"live","forever","classic_era","classic_anniversary"})do
 local s,f,notice,e=boot(client);local host={slot=1,widget={}}
 local clauses={}
 for mask=0,7 do for combat=0,1 do for enemy=0,1 do
  local terms={"@mouseover",enemy==1 and"harm"or"help",combat==1 and"combat"or"nocombat"}
  for bit,key in ipairs({"shift","ctrl","alt"})do
   terms[#terms+1]=(math.floor(mask/2^(bit-1))%2==1 and"mod:"or"nomod:")..key
  end
  clauses[#clauses+1]="["..table.concat(terms,",").."] "..(101+mask+combat*8+enemy*16)
 end end end
 local body="#showtooltip\n/cast "..table.concat(clauses,"; ")
 local function expected()
  local m=0;for i,key in ipairs({"s","c","a"})do if s.mods:find(key,1,true)then m=m+2^(i-1)end end
  return 101+m+(s.combat and 8 or 0)+(s.reaction=="e"and 16 or 0)
 end
 e.FluxButton={};e.UnitName=function(unit)return unit end
 e.SecureCmdOptionParse=function(options)
  for conditions,value in options:gmatch("%[([^%]]+)%]%s*(%d+)")do
   local ok=true
   for term in conditions:gmatch("[^,]+")do
    if term=="combat"and not s.combat or term=="nocombat"and s.combat then ok=false end
    if term=="harm"and s.reaction~="e"or term=="help"and s.reaction~="f"then ok=false end
    local key=term:match("^mod:(.+)$");local no=term:match("^nomod:(.+)$")
    local held={shift=e.IsShiftKeyDown(),ctrl=e.IsControlKeyDown(),alt=e.IsAltKeyDown()}
    if key and not held[key]or no and held[no]then ok=false end
   end
   if ok then return value,"mouseover"end
  end
 end
 e.C_Spell={GetSpellInfo=function(v)local id=tonumber(v);return id and {spellID=id,name="Spell"..id,iconID=id}end}
 f.Spell={GetInfo=function(id)return {name="Spell"..id}end,GetTexture=function(id)return id end}
 f.EBS={buttons={},badges={}}
 f.Bars.ForEachHost=function(fn)fn(host)end
 f.Bars.SlotProgram={Get=function()return body end,GetAll=function()return {[1]=body}end}
 local paints=0
 f.Bars.Paint={ClearCache=function()end,UpdateDisplay=function()paints=paints+1 end}
 local ns={Flux=f}
 for _,path in ipairs({"ExtraButtonSystem/Engine/Action.lua","Bars/ProgramFace.lua"})do
  assert(load(read(path),"@"..path,"t",e))("_FluxUI",ns)
 end
 local pf=f.Bars.ProgramFace
 check(pf.Needs("mouseover")and pf.Needs("mod")and pf.Needs("combat"),client.." actual program index requires mixed context")
 pf.Start();f.Context.Request(true);s.flush();check(host._fluxFace.SpellId==expected(),client.." initial actual translation")
 s.reaction="e";s.event("UPDATE_MOUSEOVER_UNIT")
 for tick=1,1200 do
  s.mods=masks[tick%8+1]
  for j=1,32 do s.event("MODIFIER_STATE_CHANGED")end
  s.target="stress-target"..tick;s.event("PLAYER_TARGET_CHANGED")
  s.reaction=tick%2==0 and"f"or"e";s.event("UPDATE_MOUSEOVER_UNIT")
  if tick%300==0 then s.combat=not s.combat;s.event(s.combat and"PLAYER_REGEN_DISABLED"or"PLAYER_REGEN_ENABLED")end
  local before=paints;s.frame();s.flush(1/120)
  check(host.slot==1 and host._fluxFaceSlot==1,client.." conditional refresh does not need a slot change")
  check(host._fluxFace.SpellId==expected(),client.." indexed same-slot face receives final mod/combat/mouseover truth every frame")
  check(paints==before+1,client.." changed identity paints once through actual subscriber route")
 end
 s.flush(.1);check(#s.timers==0 and #s.errors==0,client.." no stale timer tail or subscriber error")
 print(("CONTEXT_PROGRAM client=%s frames=1200 same_slot=1 paints=%d"):format(client,paints))
end
print(("CONTEXT_PROGRAM SUMMARY checks=%d failures=%d native_VM_FPS=NOT_RUN"):format(checks,failures))
os.exit(failures>0 and 1 or 0)
