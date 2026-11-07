-- Execute the actual Flux binding engine and secure enter/leave/hide programs
-- against the new party/pet outer-button names, units and ownership marker.
local function read(path)local f=assert(io.open(path,"rb"));local s=f:read("*a"):gsub("\r\n","\n");f:close();return s end
local text=read("tests/raid_binding_cast.lua")
local prefix=text:sub(1,assert(text:find("local function exercise(client, body)",1,true))-1)
local fixture=assert(load(prefix.."\nreturn fixture","@binding-fixture","t",_G))()
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
for _,client in ipairs({"live","forever","classic","classic_era","classic_anniversary"})do
    local e,module,cell,fire,route=fixture(client)
    local buttons={}
    for _,kind in ipairs({"party","partypet","target"})do for i=1,4 do
        local unit=kind=="target"and("party"..i.."target")or(kind..i)
        local button=cell("FluxUnitFrameOuter_"..unit,true)
        button.attrs.unit=unit
        module:RegisterFrame(button)
        buttons[#buttons+1]=button
    end end
    local heal,cleanse="/cast [@mouseover,help,nodead] Heal","/cast [@mouseover,help,nodead] Cleanse"
    check(route({"BUTTON1","SHIFT-CTRL-BUTTON2","Q","MOUSEWHEELUP"},{heal,cleanse,heal,heal}),"existing Flux hover programs applied outside combat")
    for _,button in ipairs(buttons)do
        check(button.attrs.type1=="macro"and button.attrs.macrotext1==heal,"owned party/pet primary mouse chord uses the existing Flux program")
        check(button.attrs["ctrl-shift-type2"]=="macro"and button.attrs["ctrl-shift-macrotext2"]==cleanse,"party/pet modifier order matches native secure chords")
    end
    e.combat=true
    local writes=e.writes
    for _,button in ipairs(buttons)do
        fire(button,"OnEnter")
        check(button.binds.Q and button.binds.MOUSEWHEELUP,"keyboard/wheel hover casting arms on every party and pet during combat")
        check(button.attrs.unit==button.name:match("FluxUnitFrameOuter_(.*)"),"hover casting preserves the actual owner/pet unit")
        fire(button,"OnHide")
        check(not next(button.binds),"combat leave/despawn hides clear secure hover bindings without needing OnLeave")
        button.shown=true
    end
    check(e.writes==writes,"combat hover/hide uses only prepared secure programs, no ordinary protected mutations")
end
print("Party Flux hover casting: "..checks.." checks; twelve party/pet/target tokens on five binding/secure models; native input/taint pending")
