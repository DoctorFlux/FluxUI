-- Actual status-bar click block; native panel execution/taint are not simulated.
local source=arg[1] or "StatusBars/FluxStatusBar.lua"
local f=assert(io.open(source)); local code=f:read("*a"); f:close()
local first=assert(code:find("-- Click to open reputation frame (on both bars)",1,true))
local last=assert(code:find("-- EVENT HANDLING",first,true))
local block=code:sub(first,last-1)
local checks,failures=0,0
local function check(ok,label)
    checks=checks+1
    if not ok then failures=failures+1; print("FAIL "..label) end
end
for _,family in ipairs({"retail","forever","era","anniversary","mists"}) do
 for _,initial in ipairs({"closed","PaperDollFrame","ReputationFrame"}) do
    local s={tab=initial,combat=false,calls={},proxies={}}
    local env=setmetatable({}, {__index=_G});env._G=env
    env.InCombatLockdown=function() return s.combat end
    env.IsForeverClient=function() return family=="forever" end
    local function toggle(tab)
        s.calls[#s.calls+1]=tab
        s.tab=s.tab==tab and "closed" or tab
    end
    env.ToggleCharacter=toggle
    env.CharacterMicroButton={Click=function() toggle("PaperDollFrame") end}
    env.Flux={SecureClickProxy={Attach=function(owner,opts) s.proxies[owner]=opts end}}
    local function bar()
        return {scripts={},SetScript=function(self,k,v) self.scripts[k]=v end,EnableMouse=function() end}
    end
    env.ExpBar,env.RepBar=bar(),bar()
    assert(load(block,"status reputation click block","t",env))()
    local function click(owner,button)
        local proxy=s.proxies[owner]
        if proxy and button=="LeftButton" and not s.combat then proxy.target():Click()
        else owner.scripts.OnMouseUp(owner,button) end
    end
    for _,owner in ipairs({env.ExpBar,env.RepBar}) do
        s.tab=initial;s.calls={}
        click(owner,"RightButton")
        check(#s.calls==0,"right click leaves panel alone")
        s.combat=true;click(owner,"LeftButton")
        check(#s.calls==0,"combat leaves panel alone")
        s.combat=false;click(owner,"LeftButton")
        check(#s.calls==1 and s.calls[1]=="ReputationFrame",family.."/"..initial.." left click selects reputation")
        check(s.tab==(initial=="ReputationFrame" and "closed" or "ReputationFrame"),"native toggle semantics retained")
        env.ToggleCharacter=nil;s.calls={}
        check(pcall(click,owner,"LeftButton"),"missing native function is safe")
        check(#s.calls==0,"missing native function does not open a different panel")
        env.ToggleCharacter=toggle
    end
 end
end
print(string.format("status reputation clicks: %d checks, %d failures",checks,failures))
if failures>0 then os.exit(1) end
