-- Production bank UI policy/hooks; native secure execution is not simulated.
local root=arg[1] or "."
local checks,failed=0,0
local function check(ok,label) checks=checks+1;if not ok then failed=failed+1;print("FAIL "..label) end end
local function read(path) local f=assert(io.open(root.."/"..path));local s=f:read("*a");f:close();return s end
local function slice(s,a,b) local first=assert(s:find(a,1,true));return s:sub(first,assert(s:find(b,first+1,true))-1) end
for _,family in ipairs({"forever","camelot","retail","era","anniversary","mists"}) do
 for _,provider in ipairs({"builtin","syndicator"}) do
    local native=family=="forever" or family=="camelot"
    local s={bankHooks=0,bagHooks=0,bankCallbacks=0,pages=0,mixinHooks=0,bagMixinHooks=0,timers=0,writes=0,events={}}
    local env=setmetatable({}, {__index=_G});env._G=env
    env.wipe=function(t) for k in pairs(t) do t[k]=nil end end
    env.InCombatLockdown=function() return false end
    env.GetTime=function()return 10 end
    env.UIParent={}
    env.FLUX_API={isForever=family=="forever",isCamelot=family=="camelot",HasUnifiedBankUI=function()return true end}
    local flux={Client={isForever=family=="forever",isCamelot=family=="camelot"},Cap={IsForeverGamepadUI=function()return false end},
        Events={Register=function(key,fn)s.events[key]=fn end}}
    env.Flux=flux
    local bank={IsOpen=function()return true end,RegisterBankOpen=function()s.bankCallbacks=s.bankCallbacks+1 end,
        IsBankContainer=function(id)return id==-1 end}
    env.FluxRestock={Inv={Bank=bank}}
    local function frame(isBank)
        return {HookScript=function()if isBank then s.bankHooks=s.bankHooks+1 else s.bagHooks=s.bagHooks+1 end end,
            SetScript=function()end,RegisterEvent=function()end,Update=function()end,IsShown=function()return true end,
            GetID=function()return 0 end,GetChildren=function()return end,IsObjectType=function()return true end}
    end
    env.CreateFrame=function()return frame(false) end
    env.BankFrame=frame(true)
    env.ContainerFrameCombinedBags=frame(false)
    env.BankPanelItemButtonMixin={Refresh=function()end}
    env.ContainerFrameItemButtonMixin={UpdateJunkItem=function()end}
    env.hooksecurefunc=function(target)
        if target==env.BankPanelItemButtonMixin then s.mixinHooks=s.mixinHooks+1
        elseif target==env.ContainerFrameItemButtonMixin then s.bagMixinHooks=s.bagMixinHooks+1 end
    end
    env.EventRegistry={RegisterCallback=function(_,key)if key:find("BankPanelMixin",1,true) then s.pages=s.pages+1 end end}
    env.C_Timer={After=function()s.timers=s.timers+1 end}
    env.FluxVendorJunk={RegisterListChanged=function()end,RegisterVisualRefresh=function()end}
    local ns={Flux=flux}
    assert(load(read("WindowMover/Catalog.lua"),"catalog","t",env))("_FluxUI",ns)
    check(flux.WindowMover.IsBlacklisted("BankFrame")==native,family.."/"..provider.." mover bank exclusion")
    check(not flux.WindowMover.IsBlacklisted("MerchantFrame"),"other windows remain movable")
    assert(load(read("Inventory/Restock/Junk/FluxJunkOverlay.lua"),"overlays","t",env))()
    env.FluxJunkOverlay.EnsureHooks()
    check(s.bankHooks==(native and 0 or 1),"native bank script hooks excluded; other clients retained")
    check(s.mixinHooks==(native and 0 or 1),"native bank item mixin hook excluded")
    check(s.pages==(native and 0 or 2),"native bank page callbacks excluded")
    check(s.bankCallbacks==(native and 0 or 1),"bank paint open callback excluded")
    check(s.bagMixinHooks==1 and s.bagHooks>0,"bag decorators remain active")
    s.bankHooks=0
    env.Inv={SetBankOpenLatch=function(on)s.open=on end,IsBaganatorBankViewShown=function()return false end}
    env.StillHasBankAccess=function()return false end
    env.IsBankerInteractionType=function()return true end
    local init=read("Inventory/Init.lua")
    local latch=slice(init,"\tlocal bankFrameLatchHooked","\n\tlocal Store = Inv.Store")
    assert(load(latch,"native frame latch","t",env))()
    check(s.bankHooks==(native and 0 or 2),"inventory latch leaves native scripts untouched")
    local events=slice(init,"local function HookBankOpenEvents()","local function HookScheduler()")
    assert(load(events.."\nHookBankOpenEvents()","bank events","t",env))()
    s.events.BANKFRAME_OPENED();check(s.open==true,"bank tracking opens through events")
    s.events.BANKFRAME_CLOSED();check(s.open==false,"bank tracking closes through events")
    s.events.PLAYER_INTERACTION_MANAGER_FRAME_SHOW(nil,1);check(s.open==true,"interaction tracking retained")
    local buttonSource=read("Inventory/Restock/Bank/FluxBankRestockButton.lua")
    env.UsesPlayerBagsInBank=function()return false end;env.UsesPreDFBankButtonLayout=function()return false end
    env.MatchRepairButtonSize=function()end;env.UsesAlternativeBagUI=function()return false end
    env.btn={SetParent=function()s.writes=s.writes+1 end,SetFrameStrata=function()end,SetFrameLevel=function()end,
        ClearAllPoints=function()end,SetPoint=function()end,Show=function()end}
    env.BankFrame.GetFrameStrata=function()return "HIGH" end;env.BankFrame.GetFrameLevel=function()return 1 end
    local attach=slice(buttonSource,"local function AttachToBlizzardBank(anchor)","local function AttachToCombinedBank(anchor)")
    local fn=assert(load(attach.."\nreturn AttachToBlizzardBank","restock attach","t",env))()
    check(fn(env.BankFrame)==not native,"restock does not attach to native Forever bank")
    check(s.writes==(native and 0 or 1),"no new child parent on native bank")
    env.Button={AttachToBank=function()end}
    local open=slice(buttonSource,"local function OnBankOpen()","local function OnBankClose()")
    local onOpen=assert(load(open.."\nreturn OnBankOpen","restock open","t",env))()
    s.timers=0;onOpen();check(s.timers==(native and 0 or 2),"native bank restock attach timers stop")
 end
end
print(string.format("native Forever bank: %d checks, %d failures",checks,failed));if failed>0 then os.exit(1) end
