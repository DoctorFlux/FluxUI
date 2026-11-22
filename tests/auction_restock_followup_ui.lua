-- Ordinary item buttons, one-pixel gaps, published readiness and bounded private proc art.
-- Desktop geometry/input models do not certify native clipping/controller/taint.
local checks, profiles = 0, 0
local function check(v, label) checks = checks + 1; assert(v, label) end
local root = os.getenv("FLUX_AH_ROOT") or "."
local function Fixture(hostPresent, hudPresent)
    local st = { frames=0, buttons=0, regions=0, hooks=0, clicks=0, combat=false, handlers={}, context={}, actions={},
        refreshes=0, activeGlow={}, styles={}, starts=0, stops=0, glowOptions={}, atlas={}, work={}, iconOverrides={}, nameOverrides={} }
    local env=setmetatable({}, {__index=_G}); env._G=env
    local m={}
    local function widget(kind,parent) return setmetatable({kind=kind,parent=parent,shown=true,enabled=true,scripts={},points={}}, {__index=m}) end
    function m:Fire(ev,...) if self.scripts[ev] then return self.scripts[ev](self,...) end end
    function m:SetScript(ev,fn) self.scripts[ev]=fn end
    function m:HookScript(ev,fn)
        check(ev=="OnVerticalScroll" or ev=="OnShow" or ev=="OnHide",
            "additive widget hooks track viewport scroll and profession page visibility")
        local previous=self.scripts[ev]; self.scripts[ev]=function(self,...) if previous then previous(self,...) end;fn(self,...) end
    end
    function m:Hide() local old=self.shown;self.shown=false;if old then self:Fire("OnHide") end end
    function m:Show() local old=self.shown;self.shown=true;if not old then self:Fire("OnShow") end end
    function m:IsShown() return self.shown end
    function m:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
    function m:SetEnabled(v) self.enabled=v end
    function m:SetMotionScriptsWhileDisabled(v) self.disabledMotion=v end
    function m:EnableMouse(v) self.mouse=v end
    function m:EnableMouseWheel(v) self.wheel=v end
    function m:SetParent(v) self.parent=v end
    function m:GetParent() return self.parent end
    function m:GetName() return self.name end
    function m:SetPoint(...) self.point={...};self.points[#self.points+1]=self.point end
    function m:ClearAllPoints() self.points={} end
    function m:Range()
        if self.kind=="ScrollFrame" and self.scrollChild then self:Fire("OnScrollRangeChanged",0,math.max(0,(self.scrollChild.height or 0)-(self.height or 0)))
        elseif self.parent and self.parent.kind=="ScrollFrame" then self.parent:Range() end
    end
    function m:SetSize(w,h)
        assert(not st.activeGlow[self] or self.width==w and self.height==h,"retire active art before resizing its button")
        self.width,self.height=w,h;self:Range()
    end
    function m:GetSize() return self.width,self.height end
    function m:GetWidth() return self.width end
    function m:GetHeight() return self.height end
    function m:SetFrameLevel(v) self.level=v end
    function m:GetFrameLevel() return self.level or self.parent and self.parent:GetFrameLevel() + 1 or 1 end
    function m:SetFrameStrata(v) self.strata=v end
    function m:GetFrameStrata() return self.strata or self.parent and self.parent:GetFrameStrata() or "MEDIUM" end
    function m:SetClampedToScreen(v) self.clamped=v end
    function m:RegisterForClicks(...) self.clicks={...} end
    function m:SetTexture(v) self.texture=v end
    function m:SetColorTexture(...) self.color={...} end
    function m:SetTexCoord(...) self.texCoord={...} end
    function m:SetNormalTexture(v) self.normal=v end
    function m:SetPushedTexture(v) self.pushed=v end
    function m:SetHighlightTexture(v) self.highlight=v end
    function m:SetText(v) self.text=v end
    function m:SetTextColor(...) self.textColor={...} end
    function m:SetJustifyH(v) self.justify=v end
    function m:SetJustifyV(v) self.justifyV=v end
    function m:SetWordWrap(v) self.wrap=v end
    function m:GetFont() return self.font or "font",self.fontSize or 12,self.fontFlags end
    function m:SetFont(f,s,flags) self.font,self.fontSize,self.fontFlags=f,s,flags end
    function m:SetShadowColor(...) self.shadowColor={...} end
    function m:SetShadowOffset(...) self.shadowOffset={...} end
    function m:CreateTexture() st.regions=st.regions+1;return widget("Texture",self) end
    function m:CreateFontString() st.regions=st.regions+1;return widget("FontString",self) end
    function m:SetScrollChild(child) self.scrollChild=child;self:Range() end
    function m:GetVerticalScroll() return self.offset or 0 end
    function m:SetVerticalScroll(v) self.offset=v;self:Fire("OnVerticalScroll",v) end
    for _,key in ipairs({"SetPoint","ClearAllPoints","SetSize","SetFont","SetTexture","SetText","Show","Hide","SetEnabled","EnableMouseWheel","SetFrameLevel","SetFrameStrata","SetParent"}) do
        local name,method=key,m[key]
        m[name]=function(self,...) st.work[name]=(st.work[name] or 0)+1;return method(self,...) end
    end
    env.table={};for key,value in pairs(table) do env.table[key]=value end
    env.table.sort=function(...) st.work.Sort=(st.work.Sort or 0)+1;return table.sort(...) end
    env.UIParent=widget("Frame");env.UIParent:SetSize(800,600)
    st.window=widget("Frame")
    function st.hud() env.FluxWindowFrame={GetFrame=function() return st.window end,SetOffset=function() end,ApplyBottomLiftFromStatusBar=function() end} end
    if hudPresent~=false then st.hud() end
    if hostPresent then env.FluxExtraAbilityHost=widget("NativeSecureHost") end
    env.CreateFrame=function(kind,name,parent,template)
        check(not st.combat,"no HUD frame or item button is allocated in combat")
        check(not template or template=="UIPanelScrollFrameTemplate" or template=="UIPanelButtonTemplate",
            "the renderer creates only ordinary addon-owned widgets")
        check(kind=="Frame" or kind=="Button" or kind=="ScrollFrame","HUD creates only ordinary frames, buttons and viewport")
        st.frames=st.frames+1;if kind=="Button" then st.buttons=st.buttons+1 end
        local f=widget(kind,parent);f.name,f.template=name,template;if name then check(not env[name],"dedicated frame names are immutable");env[name]=f end
        if template=="UIPanelButtonTemplate" then st.windowButton=f end
        if kind=="ScrollFrame" then
            check(template=="UIPanelScrollFrameTemplate","overflow reuses the existing cross-client native scroll template")
            local bar=widget("Slider",f);f.ScrollBar=bar
            function bar:SetValue(v) self.value=math.max(0,math.min(self.max or 0,v));f:SetVerticalScroll(self.value) end
            bar.ScrollUpButton,bar.ScrollDownButton=widget("Button",bar),widget("Button",bar)
            bar.ScrollUpButton:SetScript("OnClick",function() bar:SetValue((bar.value or 0)-46) end)
            bar.ScrollDownButton:SetScript("OnClick",function() bar:SetValue((bar.value or 0)+46) end)
            f:SetScript("OnVerticalScroll",function(self,v) self.nativeVertical=(self.nativeVertical or 0)+1;bar.value=v end)
            f:SetScript("OnScrollRangeChanged",function(self,_,max) self.nativeRange=(self.nativeRange or 0)+1;bar.max=max end)
        end
        return f
    end
    env.InCombatLockdown=function() return st.combat end
    env.GetMoneyString=function(copper) return tostring(copper).." copper" end
    env.FluxItemClass={GetIcon=function(id) return st.iconOverrides[id] or id+9000 end,GetName=function(id) return st.nameOverrides[id] or "Item"..id end}
    env.GameTooltip={SetOwner=function(_,owner) st.tipOwner=owner end,IsOwned=function(_,owner) return st.tipOwner==owner end,
        ClearLines=function() st.work.TipClear=(st.work.TipClear or 0)+1;st.tipLines={} end,AddLine=function(_,text) st.tipLines[#st.tipLines+1]=text end,
        Show=function() st.work.TipShow=(st.work.TipShow or 0)+1;st.tip=true end,
        Hide=function() st.work.TipHide=(st.work.TipHide or 0)+1;st.tip=false end}
    local function Start(slot,style)
        check(slot.kind=="Button" and slot.active and slot.enabled,"only a usable visible ordinary item button owns a proc effect")
        check(not st.activeGlow[slot],"old private effect is stopped before resizing/reassignment")
        st.activeGlow[slot],st.styles[slot],st.starts=true,style,st.starts+1
    end
    local function Stop(slot,style)
        check(st.activeGlow[slot] and st.styles[slot]==style,"each private effect stops through its original renderer")
        st.activeGlow[slot],st.stops=nil,st.stops+1
    end
    st.lcg={
        ProcGlow_Start=function(slot,opt)
            check(opt.key=="FluxRestockFollowup" and opt.startAnim==false and opt.color==nil,"proc uses its own key, native art colors and no repeated birth animation")
            check(not st.glowOptions[opt],"each proc start receives a fresh options table");st.glowOptions[opt]=true
            Start(slot,"proc")
            local overlay=widget("Frame",slot)
            overlay:SetPoint("TOPLEFT",slot,"TOPLEFT",-slot.width*.2,slot.height*.2)
            overlay:SetPoint("BOTTOMRIGHT",slot,"BOTTOMRIGHT",slot.width*.2,-slot.height*.2)
            slot._ProcGlowFluxRestockFollowup=overlay
        end,
        ProcGlow_Stop=function(slot,key) check(key=="FluxRestockFollowup","proc cleanup retains its private key");Stop(slot,"proc");slot._ProcGlowFluxRestockFollowup=nil end,
        ButtonGlow_Start=function(slot)
            Start(slot,"button")
            local overlay=widget("Frame",slot)
            overlay.width,overlay.height=slot.width*1.4,slot.height*1.4
            overlay:SetScript("OnHide",function() if overlay.fading then slot._ButtonGlow=nil;Stop(slot,"button") end end)
            slot._ButtonGlow=overlay
        end,
        ButtonGlow_Stop=function(slot) if slot._ButtonGlow then slot._ButtonGlow.fading=true end end,
    }
    st.lbg={
        ShowOverlayGlow=function(slot)
            if slot.__LBGoverlay then return end -- the actual classic library retains fading geometry
            Start(slot,"classic")
            local overlay=widget("Frame",slot);overlay.width,overlay.height=slot.width*1.4,slot.height*1.4
            slot.__LBGoverlay=overlay
            overlay:SetScript("OnHide",function() if overlay.fading then slot.__LBGoverlay=nil;Stop(slot,"classic") end end)
        end,
        HideOverlayGlow=function(slot) if slot.__LBGoverlay then slot.__LBGoverlay.fading=true end end,
    }
    env.LibStub=function(name,optional)
        st.work.ArtLookup=(st.work.ArtLookup or 0)+1
        check(optional==true,"proc artwork only queries optional private libraries")
        if name=="LibCustomGlow-1.0" then return not st.noLCG and st.lcg or nil end
        if name=="LibButtonGlow-1.0" then return st.classicLoaded and st.lbg or nil end
        error("unexpected art provider")
    end
    env.ActionButton_ShowOverlayGlow=function() error("HUD must not call native action-button glow") end
    env.ActionButton_HideOverlayGlow=env.ActionButton_ShowOverlayGlow
    env.ActionButtonSpellAlertManager=setmetatable({}, {__index=function() error("HUD must not join native spell-alert management") end})
    env.FluxEffectGlow={InstallSAO=function() error("HUD must not join SAO spell membership") end,Set=function() error("private art does not register SAO state") end}
    env.C_Timer=setmetatable({}, {__index=function() error("HUD must not schedule polling/actions") end})
    env.hooksecurefunc=function(target,name,fn)
        check(target==env.FluxWindowFrame and (name=="SetOffset" or name=="ApplyBottomLiftFromStatusBar"),"placement only post-hooks the existing addon window API")
        st.hooks=st.hooks+1;local old=target[name];target[name]=function(...) old(...);fn(...) end
    end
    local F={}
    F.IsContextOpen=function(kind) check(st.publishing,"paint never queries a vendor owner that can rebuild the stage");return st.context[kind]==true end
    F.GetState=function() return st.state end
    F.GetProfessionWindowAction=function()
        local state=st.state
        if state and (state.kind=="craft" or state.kind=="crafting" or state.kind=="profession") then return state end
    end
    F.CanAct=function() error("paint must consume published canAct without querying action owners again") end
    F.Refresh=function()
        st.refreshes=st.refreshes+1
        if st.state then
            st.publishing=true;st.state.contextOpen=F.IsContextOpen(st.state.kind);st.publishing=false
            st.state.canAct=not st.blocked and (st.state.kind=="craft" and st.craftReady~=false
                or st.state.kind~="crafting" and st.state.contextOpen==true)
        end
        F.Paint(st.state)
    end
    local function RecordAction(state)
        local action={};for id,q in pairs(state.items or {}) do action[id]=q end
        st.clicks=st.clicks+1;st.actions[st.clicks]=action
    end
    F.Click=function(...)
        check(select("#",...)==0 and st.state.kind~="profession" and st.hardware and not st.combat,
            "ordinary work dispatches the same no-ID whole-stage intent from a fresh press")
        RecordAction(st.state)
    end
    F.ClickProfession=function(state)
        check(state==st.state and state.kind=="profession" and st.hardware and not st.combat,
            "profession presses dispatch only the exact displayed opener")
        RecordAction(state)
    end
    F.ClickProfessionWindowAction=function(action)
        check(action==F.GetProfessionWindowAction() and st.hardware and not st.combat
            and action.canAct and not action.nativeCraftPrepared,
            "the dock sends the published usable profession action through a player press")
        RecordAction(action)
    end
    env.FluxAuctionRestock={Followup=F}
    local L={AH_TITLE="Restock",AH_FOLLOWUP_HELP="This restock only.",AH_FOLLOWUP_ITEM="%d %s"}
    for _,kind in ipairs({"MAIL","BANK","VENDOR","CRAFT","CRAFTING","WAITING","AUCTION"}) do L["AH_FOLLOWUP_"..kind]=kind.." %d %s" end
    L.AH_FOLLOWUP_PROFESSION="OPEN %s"
    L.AH_FOLLOWUP_VENDOR_ITEM="Get %d × %s"
    L.AH_FOLLOWUP_VENDOR_PAIR="Get %d × %s\n%d × %s"
    L.AH_FOLLOWUP_COMPANION_VENDOR_HELP="Visit a vendor selling the queued materials."
    L.AH_FOLLOWUP_PROFESSION_HELP="Open the profession before crafting."
    L.AH_FOLLOWUP_NATIVE_CRAFT="Open recipe: %s"
    L.AH_FOLLOWUP_NATIVE_CRAFT_PREPARED="Click Blizzard Create (%d)"
    L.AH_FOLLOWUP_WINDOW_PROFESSION="Open profession"
    L.AH_FOLLOWUP_WINDOW_CRAFT="Craft next"
    L.AH_FOLLOWUP_WINDOW_PROCESS="Process"
    L.AH_FOLLOWUP_WINDOW_PREPARED="Use Create (%d)"
    L.AH_FOLLOWUP_RESUME="Resume %d × %s"
    L.AH_FOLLOWUP_RESUME_COMPLETE="Count %d × %s"
    L.AH_FOLLOWUP_RESUME_HELP="Count %d carried and continue %d."
    L.AH_FOLLOWUP_RESUME_COMPLETE_HELP="Count %d carried and finish."
    L.AH_FOLLOWUP_NATIVE_CRAFT_HELP="Press to reveal the exact recipe, then use Create in the profession window."
    L.AH_FOLLOWUP_NATIVE_CRAFT_BATCH_HELP="Press to reveal the exact recipe. Use Create in the profession window with quantity %d."
    L.AH_FOLLOWUP_NATIVE_CRAFT_PREPARED_HELP="Quantity %d is set. Click Create at the bottom of Blizzard's profession window."
    local events={Register=function(ev,fn) check(not st.handlers[ev],"UI event has one owned listener");st.handlers[ev]=fn end,
        Unregister=function(ev,fn) check(st.handlers[ev]==fn,"owned size listener is retired without removing another callback");st.handlers[ev]=nil end}
    local cap={HasAtlas=function(name)
        st.work.AtlasLookup=(st.work.AtlasLookup or 0)+1
        check(name=="UI-HUD-ActionBar-Proc-Start-Flipbook" or name=="UI-HUD-ActionBar-Proc-Loop-Flipbook","proc artwork checks both central atlas capabilities")
        return st.atlas[name]~=false
    end}
    local path=os.getenv("FLUX_FOLLOWUP_UI_SOURCE") or root.."/Inventory/Restock/Auction/FluxAuctionRestockFollowupUI.lua"
    local chunk=assert(loadfile(path,"t",env));if setfenv then setfenv(chunk,env) end
    st.flux={Events=events,Capabilities=cap}
    chunk("_FluxUI",{Flux=st.flux,FluxOptionsLocale=L})
    function st.emit(ev) if st.handlers[ev] then st.handlers[ev]() end end
    function st.press(index)
        local slot=F.icons[index or 1]
        if not slot or not slot:IsVisible() or not slot.enabled then return end
        st.hardware=true;slot:Fire("OnClick","LeftButton");st.hardware=false
    end
    function st.glows()
        local n=0
        for _,slot in ipairs(F.icons or {}) do
            if slot.glowLib or slot.glowing or slot._ProcGlowFluxRestockFollowup or slot.__LBGoverlay or slot._ButtonGlow then n=n+1 end
        end
        return n
    end
    return F,st,env
end
local function State(kind,n)
    local s={kind=kind,name="Restock",quantity=0,items={}}
    for i=n,1,-1 do s.items[1000+i]=i+1;s.quantity=s.quantity+i+1 end
    return s
end
if FLUX_FOLLOWUP_UI_FIXTURE_EXPORT then return Fixture, State end
local function CheckItems(F,n)
    local f=F.frame
    check(f.kind=="Frame" and f.mouse==false and not f.scripts.OnClick,"container and caption are inert, never one giant action button")
    check(f.itemCount==n and F.buttons==F.icons and F.button==F.icons[1],"all current items retain pooled independent button handles")
    check(f.label.fontSize==14 and f.label.fontFlags=="OUTLINE" and f.label.shadowColor[4]==1,"caption retains outlined14px high contrast")
    check(f.label.point[5]==-f.viewportHeight and f.caption.height==40 and f.viewportHeight+f.caption.height==f.height,"caption stays outside scrolling and inside bounded host")
    for i=1,n do
        local slot=F.icons[i]
        check(slot.kind=="Button" and slot.parent==f.content and slot.active and slot:IsShown(),"each item has its own ordinary action button")
        check(slot.itemID==1000+i and slot.quantity==i+1 and slot.icon.texture==10000+i and slot.count.text==tostring(i+1),"sorted physical item identities and badges remain exact")
        check(slot.width==f.iconSize and slot.height==f.iconSize and slot.size>=32 and slot.clicks[1]=="LeftButtonUp","each item has a normal readable square click rectangle")
        check(slot.normal==slot.border and slot.border.texture=="Interface\\Buttons\\UI-Quickslot2"
            and slot.pushed=="Interface\\Buttons\\UI-Quickslot-Depress" and slot.highlight=="Interface\\Buttons\\ButtonHilight-Square",
            "normal, pressed and hover artwork belong only to each square item button")
        check(slot.x>=0 and slot.x+slot.size<=f.content.width and slot.y>=0 and slot.y+slot.size<=f.content.height,"every item rectangle belongs to the complete scroll content")
        local offset=f.scroll and f.scroll:GetVerticalScroll() or 0
        check(slot.enabled==(F.GetState().canAct==true and slot.y+slot.size>offset and slot.y<offset+f.viewportHeight),"offscreen item buttons are disabled and visible action buttons remain reachable")
        if slot.enabled and slot._ProcGlowFluxRestockFollowup then
            local overlay=slot._ProcGlowFluxRestockFollowup
            check(overlay.width==slot.width*1.4 and overlay.height==slot.height*1.4 and #overlay.points==1
                and overlay.point[1]=="CENTER" and overlay.point[2]==slot and overlay.point[3]=="CENTER"
                and overlay.point[4]==0 and overlay.point[5]==0 and overlay.mouse==false,
                "the private proc uses explicit centered bounds for the current button size and no mouse input")
        end
        if i>1 then
            local prev=F.icons[i-1]
            check(slot.y==prev.y and slot.x-prev.x-prev.size==1 or slot.y-prev.y-prev.size==1,
                "neighboring item button rectangles have exactly one pixel of horizontal or vertical gap")
        end
    end
end
local function CheckDock(frame, badge, surface, anchor, point, relativePoint)
    check(frame:IsVisible() and badge:IsVisible() and frame:GetParent()==surface
        and frame.point[1]==point and frame.point[2]==anchor and frame.point[3]==relativePoint,
        "the shared reminder follows its actual profession surface and anchor")
    check(frame.width==196 and frame.height==42 and badge.width==badge.height
        and frame.label.wrap and frame.label.justify=="LEFT" and not frame.mouse,
        "the compact dock keeps its square item badge, readable caption, and inert container")
end
do
    local F,st,env=Fixture(true)
    local native=env.CreateFrame("Frame",nil,env.UIParent)
    local page=env.CreateFrame("Frame",nil,native)
    local book=env.CreateFrame("Frame",nil,native)
    local spec=env.CreateFrame("Frame",nil,native)
    page:SetFrameLevel(100);book:SetFrameLevel(102);spec:SetFrameLevel(104)
    book:Hide();spec:Hide()
    native.CraftingPage,native.BookPage,native.Pages=page,book,{page,book,spec}
    page.CreateButton=env.CreateFrame("Button",nil,page)
    env.ProfessionsFrame=native
    local action=State("craft",1)
    st.state=action
    F.GetProfessionWindowAction=function() return action end
    F.Refresh()
    local dock,badge=F.frame,F.icons[1]
    CheckDock(dock,badge,native,page.CreateButton,"BOTTOMRIGHT","TOPRIGHT")
    check(dock.label.text=="CRAFT 2 Restock" and badge.count.text=="2" and badge.icon.texture==10001
        and dock:GetFrameLevel()>page:GetFrameLevel() and not st.windowButton,
        "standalone FluxUI shows the original artwork and caption beside Create without a second button")
    page:Hide();book:Show()
    CheckDock(dock,badge,native,native,"TOPRIGHT","TOPRIGHT")
    check(dock:GetFrameLevel()>book:GetFrameLevel(), "the same control clears the Book page when Create is unavailable")
    book:Hide();spec:Show()
    check(dock:IsVisible() and dock:GetFrameLevel()>spec:GetFrameLevel(), "the same action is available on other profession tabs")
    st.press(1)
    check(st.clicks==1 and st.actions[1][1001]==2, "the docked original badge routes the standalone request once")

    spec:Hide();page:Show()
    local hint=env.CreateFrame("Frame",nil,page)
    F.SetProfessionSurfaceReader(function() return native,false,hint,"above" end)
    CheckDock(dock,badge,native,hint,"BOTTOMRIGHT","TOPRIGHT")
    check(dock:GetFrameLevel()>hint:GetFrameLevel(), "the badge stays above a visible native preparation hint")
    action.nativeCraft,action.nativeCraftPrepared=true,2
    F.Refresh();badge:Fire("OnEnter");st.press(1)
    check(dock.label.text=="Click Blizzard Create (2)" and badge.count.text=="2" and not badge.enabled
        and st.glows()==0 and st.clicks==1 and st.tipLines[4]=="Quantity 2 is set. Click Create at the bottom of Blizzard's profession window.",
        "the prepared native batch shows its count and original Create instructions without a second dispatch")

    action.kind,action.nativeCraftPrepared="crafting",nil
    F.Refresh();st.press(1)
    check(dock:IsVisible() and dock.parent==native and dock.label.text=="CRAFTING 2 Restock"
        and not badge.enabled and st.glows()==0 and st.clicks==1,
        "the native dock shows running-craft information without an actionable badge")
    action=nil
    st.state=State("mail",1)
    F.Refresh()
    check(dock:IsVisible() and dock.parent==env.UIParent and dock.point[2]==env.FluxExtraAbilityHost
        and dock.label.text=="MAIL 2 Restock" and not st.windowButton,
        "the shared widget returns mail to the HUD even with a profession open")
end
do
    local F,st,env=Fixture(false)
    local function QueueCraft(quantity)
        return {kind="craft", name="Green Silk Pack", quantity=quantity, items={[5764]=quantity},
            nativeCraft=true, nativeCraftOperations=quantity}
    end
    local action=QueueCraft(10)
    local published=QueueCraft(10)
    local activated, presses=nil,0
    F.GetProfessionWindowAction=function() return published end
    F.ClickProfessionWindowAction=function(shown)
        check(st.hardware, "the shared item control dispatches from a player press")
        activated=shown
        if shown==published then presses=presses+1 end
    end
    st.state=action
    F.Refresh()
    local hud, badge=F.frame,F.icons[1]
    check(hud:IsVisible() and hud.parent==env.UIParent and hud.point[2]==st.window and badge.enabled and badge.quantity==10,
        "a ready queue craft has a HUD button before the optional extra ability host and native profession exist")

    local native=env.CreateFrame("Frame",nil,env.UIParent)
    local page=env.CreateFrame("Frame",nil,native)
    native.CraftingPage=page
    page.CreateButton=env.CreateFrame("Button",nil,page)
    native:Hide()
    env.ProfessionsFrame=native
    st.handlers.ADDON_LOADED(nil,"Blizzard_Professions")
    check(hud:IsVisible() and not st.windowButton, "a hidden late-loaded profession leaves the HUD craft available")
    native:Show()
    CheckDock(hud,badge,native,page.CreateButton,"BOTTOMRIGHT","TOPRIGHT")
    check(F.frame==hud and F.icons[1]==badge and not st.windowButton,
        "late opening moves the same live badge into the profession window")

    local workbench=env.CreateFrame("Frame",nil,page)
    local anchor=env.CreateFrame("Frame",nil,workbench)
    F.SetProfessionSurfaceReader(function() return workbench,true,anchor end)
    CheckDock(hud,badge,workbench,anchor,"CENTER","CENTER")
    local previous=published
    published=QueueCraft(9)
    activated=nil
    st.press(1)
    check(presses==0 and (activated==nil or activated==previous),
        "a late queue publication cannot turn the visible old reminder into an unseen new action")
    action=QueueCraft(9)
    st.state=action
    F.Refresh()
    check(hud:IsVisible() and badge.enabled and badge.quantity==9 and badge.count.text=="9"
        and hud.label.text=="Open recipe: Green Silk Pack" and not st.windowButton,
        "a partial receipt updates the original visible icon and caption in Flowcraft")
    st.press(1)
    check(activated==published and activated~=action and presses==1,
        "the Flowcraft dock forwards the exact painted token once")

    st.combat=true;st.emit("PLAYER_REGEN_DISABLED")
    st.press(1)
    check(not hud:IsVisible() and st.glows()==0 and presses==1, "combat retires the docked input and glow")
    st.combat=false;st.emit("PLAYER_REGEN_ENABLED")
    CheckDock(hud,badge,workbench,anchor,"CENTER","CENTER")
    workbench:Hide()
    F.RefreshProfessionLayer()
    CheckDock(hud,badge,native,page.CreateButton,"BOTTOMRIGHT","TOPRIGHT")
    native:Hide()
    check(hud:IsVisible() and hud.parent==env.UIParent and hud.point[2]==st.window and badge.quantity==9
        and hud.width==196 and hud.height==92 and not st.windowButton,
        "closing professions restores the same incomplete order and its original HUD layout")
    st.press(1)
    check(st.clicks==1 and st.actions[1][5764]==9 and presses==1,
        "the restored floating badge uses the existing HUD click path")
end
do
    local F,st,env=Fixture(true)
    local native=env.CreateFrame("Frame",nil,env.UIParent)
    native:SetFrameStrata("HIGH");native:SetFrameLevel(140)
    local page=env.CreateFrame("Frame",nil,native)
    page:SetFrameLevel(155)
    native.CraftingPage=page
    local book=env.CreateFrame("Frame",nil,native)
    book:SetFrameLevel(160);book:Hide()
    native.BookPage=book
    env.ProfessionsFrame=native
    local unrelated=env.CreateFrame("Frame",nil,env.UIParent)
    unrelated:SetFrameStrata("DIALOG");unrelated:SetFrameLevel(350)
    env.StaticPopup1=unrelated
    st.state=State("vendor",1)
    st.context.vendor=true
    F.Refresh()
    local anchor=F.frame.point
    check(F.frame:GetFrameStrata()=="HIGH" and F.frame:GetFrameLevel()==163
        and unrelated:GetFrameStrata()=="DIALOG" and unrelated:GetFrameLevel()==350,
        "the vendor HUD still clears the visible native craft page without moving an unrelated dialog")
    local workbench=env.CreateFrame("Frame",nil,page)
    workbench:SetFrameLevel(185)
    local work=env.CreateFrame("Frame",nil,workbench)
    local plan=env.CreateFrame("Frame",nil,work)
    local graph=env.CreateFrame("Frame",nil,plan)
    local card=env.CreateFrame("Button",nil,graph)
    local fold=env.CreateFrame("Button",nil,card)
    fold:EnableMouse(true)
    check(F.SetProfessionSurfaceReader(function() return workbench end),"the Forever companion supplies the visible workbench")
    check(F.frame:GetFrameStrata()=="HIGH" and F.frame:GetFrameLevel()==193 and F.frame:GetFrameLevel()>fold:GetFrameLevel()
        and F.frame.point==anchor and fold.mouse,"the HUD clears the Flowchart's nested mouse blocker without moving the anchor")
    workbench:Hide();page:Hide();book:Show();F.RefreshProfessionLayer()
    check(F.frame:GetFrameLevel()==168,"the HUD keeps its input above the visible native profession Book page")
    book:Hide();page:Show();F.RefreshProfessionLayer()
    local shell=env.CreateFrame("Frame",nil,env.UIParent)
    shell:SetFrameStrata("DIALOG");shell:SetFrameLevel(12)
    local classic=env.CreateFrame("Frame",nil,shell)
    classic:SetFrameLevel(48)
    check(F.SetProfessionSurfaceReader(function() return classic end), "the companion supplies its unnamed workbench")
    check(F.frame:GetFrameStrata()=="DIALOG" and F.frame:GetFrameLevel()==100
        and F.icons[1]:GetFrameStrata()=="DIALOG" and F.frame.point==anchor,
        "the same position and click target now outrank the visible Classic workbench")
    local levels, layers=st.work.SetFrameLevel, st.work.SetFrameStrata
    F.RefreshProfessionLayer();F.Refresh()
    check(st.work.SetFrameLevel==levels and st.work.SetFrameStrata==layers,
        "unchanged visible layers do not rewrite either frame property")
    shell:Hide()
    F.RefreshProfessionLayer()
    check(F.frame:GetFrameStrata()=="HIGH" and F.frame:GetFrameLevel()==163,
        "hiding the companion shell restores the still-visible native layer")
    native:Hide()
    F.RefreshProfessionLayer()
    check(F.frame:GetFrameStrata()=="HIGH" and F.frame:GetFrameLevel()==100 and F.frame.point==anchor
        and F.icons[1].enabled and not F.frame.mouse,
        "closing professions restores ordinary HUD stacking and mouse ownership")
    env.TradeSkillFrame=shell
    shell:Show()
    check(F.SetProfessionSurfaceReader(function() return nil end), "the companion can clear its visible surface")
    check(F.frame:GetFrameStrata()=="DIALOG" and F.frame:GetFrameLevel()==100 and F.frame.parent==env.UIParent,
        "a visible standard legacy profession frame still sets the nearby vendor HUD layer")
    env.TradeSkillCreateButton=env.CreateFrame("Button",nil,shell)
    env.TradeSkillCreateButton:SetFrameLevel(80)
    st.state=State("craft",1);F.Refresh()
    CheckDock(F.frame,F.icons[1],shell,env.TradeSkillCreateButton,"BOTTOMRIGHT","TOPRIGHT")
    check(F.frame:GetFrameStrata()=="DIALOG" and F.frame:GetFrameLevel()>env.TradeSkillCreateButton:GetFrameLevel(),
        "the original badge inherits the legacy tradeskill shell's visible layer")
    local overview=env.CreateFrame("Frame",nil,shell)
    F.SetProfessionSurfaceReader(function() return overview,false end)
    CheckDock(F.frame,F.icons[1],overview,overview,"TOPRIGHT","TOPRIGHT")
    overview:Hide();F.RefreshProfessionLayer()
    CheckDock(F.frame,F.icons[1],shell,env.TradeSkillCreateButton,"BOTTOMRIGHT","TOPRIGHT")
end
for _,client in ipairs({"Retail","Forever","MoP","Era","Anniversary"}) do
    profiles=profiles+1
    local F,st,env=Fixture(client=="Retail" or client=="Forever")
    F.Paint(nil);st.state=State("waiting",2);F.Refresh();check(st.frames==0,"waiting never allocates question-mark HUD or focus targets")
    st.state=State("mail",2);st.combat=true;F.Refresh();check(st.frames==0,"new work in combat allocates no buttons or decorations")
    st.combat=false;st.context.mail=true;st.emit("PLAYER_REGEN_ENABLED");CheckItems(F,2)
    local point=F.frame.point
    check(F.frame:GetFrameStrata()=="HIGH" and F.frame.level==100 and F.icons[1]:GetFrameStrata()=="HIGH" and not F.frame.mouse,
        "the reminder and item input sit above the standard profession panel while the container stays mouse inert")
    if env.FluxExtraAbilityHost then
        check(point[1]=="RIGHT" and point[2]==env.FluxExtraAbilityHost and point[3]=="LEFT"
            and point[4]==16 and point[5]==-68,"native host placement offsets the reminder further right and down")
    else
        check(point[1]=="CENTER" and point[2]==st.window and point[3]=="TOPLEFT"
            and point[4]==-66 and point[5]==26,"fallback placement applies the same rightward and downward movement")
    end
    check(env.FluxAuctionRestockFollowupButton==F.button and F.button.name=="FluxAuctionRestockFollowupButton",
        "the first real item button preserves its existing named binding/macro target")
    check(F.frame.width==196 and F.frame.height==88 and st.buttons==2,"two-item appearance retains the existing compact geometry")
    local before=st.clicks
    F.icons[2]:Fire("OnEnter");check(st.tip and st.tipOwner==F.icons[2] and st.tipLines[1]=="3 Item1002"
        and st.tipLines[2]=="MAIL 5 Restock" and #st.tipLines==3,"each icon owns a bounded tooltip for its own quantity/name and current stage")
    st.press(2);check(st.clicks==before+1 and st.actions[st.clicks][1001]==2 and st.actions[st.clicks][1002]==3,"pressing the second real item handles the complete current stage")
    for _,kind in ipairs({"mail","bank","vendor","auction"}) do
        st.state=State(kind,2);st.context={[kind]=true};F.Refresh();F.Refresh()
        check(F.icons[1].enabled and F.icons[2].enabled and not F.frame.scripts.OnClick and st.glows()==2,"matching usable interactions glow each ordinary item button without panel activation")
        if kind=="auction" then
            st.state.offer={total=125};F.Refresh();F.icons[2]:Fire("OnEnter")
            check(st.tipLines[3]=="125 copper","the auction tooltip shows the displayed offer's full price")
            before=st.clicks;st.press(2)
            check(F.frame.label.text=="AUCTION 5 Restock" and st.clicks==before+1
                and st.actions[st.clicks][1001]==2,"an eligible auction action paints and dispatches through the same item buttons")
        end
        local starts=st.starts;F.Refresh();check(st.starts==starts,"unchanged usable items do not restart proc effects")
        st.blocked=true;F.Refresh()
        check(st.glows()==0 and not F.icons[1].enabled and not F.icons[2].enabled,"busy or accepted stages disable input and stop art despite an open context")
        local before=st.clicks;st.hardware=true;F.icons[1]:Fire("OnClick");st.hardware=false
        check(st.clicks==before,"a stale callback cannot act when the published stage is busy or accepted")
        st.blocked=false;st.context={};F.Refresh()
        check(st.glows()==0 and not F.icons[1].enabled,"closed matching contexts cannot retain usable-item art")
    end
    st.context={vendor=true}
    local sizes={44,40,36,34,32};local heights={92,88,84,187,377};local widths={196,196,196,196,205}
    for j,n in ipairs({1,2,5,20,60}) do
        st.state=State("vendor",n);F.Refresh();CheckItems(F,n)
        check(F.frame.width==widths[j] and F.frame.height==heights[j] and F.frame.iconSize==sizes[j] and not F.frame.scroll,"normal1..60 layouts retain size/position and need no viewport")
    end
    for i=1,60 do before=st.clicks;st.press(i);local num=0;for _ in pairs(st.actions[st.clicks]) do num=num+1 end;check(st.clicks==before+1 and num==60,"every real icon press requests every stage target once") end
    local old=F.icons[60];st.state=State("mail",1);F.Refresh()
    check(F.icons[60]==old and not old.active and not old:IsShown() and old.itemID==nil and old.quantity==nil and old.count.text=="","retired pooled button clears identity/count and hides")
    before=st.clicks;st.hardware=true;old:Fire("OnClick");st.hardware=false;old:Fire("OnEnter")
    check(st.clicks==before and not st.tip,"retired callbacks cannot act or reveal stale tooltips")
    st.state={kind="craft",name="Bandage",quantity=2,itemID=200,items={},task={parentID=200,operations=2,yield=3}};F.Refresh()
    check(F.icons[1].count.text=="6" and F.frame.label.text=="CRAFT 2 Bandage","craft icon counts output items while caption counts operations")
    st.state.kind="crafting";F.Refresh();before=st.clicks;st.press(1);check(st.clicks==before and not F.icons[1].enabled,"running craft cannot dispatch another protected action")
    st.state=State("vendor",2);st.context={vendor=true};F.Refresh();F.icons[2]:Fire("OnEnter")
    st.combat=true;st.emit("PLAYER_REGEN_DISABLED");check(not F.frame:IsShown() and st.glows()==0 and not st.tip,"combat hides every action and tooltip without an effect owner")
    st.hardware=true;F.icons[2]:Fire("OnClick");st.hardware=false;F.icons[2]:Fire("OnEnter");check(st.clicks==before and not st.tip,"stale combat callbacks cannot act or display a tooltip")
    st.combat=false;st.emit("PLAYER_REGEN_ENABLED");check(F.frame:IsShown() and st.glows()==2,"combat exit restores usable item effects without actions")
    st.state=State("waiting",2);F.Refresh();env.FluxWindowFrame:SetOffset();st.emit("PLAYER_LOGIN")
    check(not F.frame:IsShown() and st.glows()==0 and not st.handlers.DISPLAY_SIZE_CHANGED,"waiting retires focus and dynamic size watchers")
    st.state=nil;F.Refresh();check(not F.frame:IsShown() and st.hooks==2,"completion does not allocate or reactivate another panel")
end
do
    local F,st,env=Fixture(true)
    st.state=State("vendor",2);F.Refresh();F.icons[2]:Fire("OnEnter")
    st.state.items[1002],st.state.quantity=7,9;F.Refresh()
    check(st.tipOwner==F.icons[2] and st.tipLines[1]=="7 Item1002" and #st.tipLines==3,
        "hovered item tooltip refreshes that item's changed quantity without listing its neighbors")
    st.state.items[1001],st.state.quantity=nil,7;F.Refresh()
    check(not st.tip and not F.icons[2].active and env.FluxAuctionRestockFollowupButton==F.icons[1],
        "pool compaction retires the old tooltip and preserves the original named first button")
    F.icons[1]:Fire("OnEnter")
    check(st.tipLines[1]=="7 Item1002" and #st.tipLines==3,
        "a reused first button shows its current item identity and physical quantity")
end
-- Large lists use expanded columns first, then a real bounded scroll viewport.
for _,n in ipairs({193,500,1000}) do
    local F,st,env=Fixture(true)
    st.state=State("vendor",n);st.context.vendor=true;F.Refresh();CheckItems(F,n)
    local f=F.frame
    check(f.width<=768 and f.height<=568 and f.iconSize==32,"large list host stays within800x600 UIParent margins without unreadable icons")
    check(f.columns>8 and f.label.width<=f.width,"over-height lists expand columns before clipping their fixed caption")
    if n==193 then check(not f.overflow and not f.scroll and f.contentHeight+40==f.height,"193 items fit expanded columns without unnecessary scroll controls")
    else
        local scroll,bar=f.scroll,f.scroll.ScrollBar
        check(f.overflow and f.maxScroll>0 and scroll.scrollChild==f.content and f.content.parent==scroll,"one bounded native viewport retains every large-list item button")
        check(scroll.template=="UIPanelScrollFrameTemplate" and scroll.mouse==false and scroll.wheel and bar:IsShown(),"viewport is wheel-only with native cursor scrollbar controls")
        check(scroll.nativeRange and scroll.scripts.OnScrollRangeChanged and scroll.scripts.OnVerticalScroll,"native range/vertical handlers survive the added eligibility hook")
        check(not F.icons[n].enabled and F.icons[1].enabled,"offscreen item buttons leave native focus until scrolled into view")
        local before=st.clicks;st.hardware=true;F.icons[n]:Fire("OnClick");st.hardware=false;F.icons[n]:Fire("OnEnter")
        check(st.clicks==before and not st.tip,"fully offscreen item callbacks cannot dispatch or show stale tooltip")
        F.icons[1]:Fire("OnEnter");check(st.tip,"visible item tooltip is initially owned")
        scroll:Fire("OnMouseWheel",-10000)
        check(scroll:GetVerticalScroll()==f.maxScroll and scroll.nativeVertical and not st.tip,"wheel clamps to final row and retires tooltip leaving its viewport")
        check(F.icons[n].y-scroll:GetVerticalScroll()>=0 and F.icons[n].y+32-scroll:GetVerticalScroll()<=f.viewportHeight,"the final item becomes fully reachable inside the viewport")
        F.icons[n]:Fire("OnEnter")
        check(st.tipLines[1]==tostring(n+1).." Item"..(1000+n) and #st.tipLines==3,
            "hovering a large-list item never expands the tooltip into the whole stage list")
        st.press(n);check(st.clicks==before+1 and st.actions[st.clicks][1001] and st.actions[st.clicks][1000+n],"last real item button still requests every current-stage target")
        before=st.clicks
        for i=1,n do
            local slot=F.icons[i];bar:SetValue(math.min(f.maxScroll,slot.y))
            check(slot.y+slot.size>scroll:GetVerticalScroll() and slot.y<scroll:GetVerticalScroll()+f.viewportHeight,"every item can be reached through the native cursor scrollbar")
        end
        bar:SetValue(0);bar.ScrollDownButton:Fire("OnClick");check(scroll:GetVerticalScroll()==46,"native scrollbar step buttons retain their cursor path")
        bar.ScrollUpButton:Fire("OnClick");check(scroll:GetVerticalScroll()==0 and st.clicks==before,"scrollbar navigation never activates a restock item")
        bar:SetValue(f.maxScroll);check(scroll:GetVerticalScroll()>0,"shrinking begins with a genuinely scrolled large list")
        local frames=st.frames;st.state=State("mail",1);st.context={};F.Refresh()
        check(st.frames==frames and f.width==196 and f.height==92 and not f.overflow and not scroll.wheel and not bar:IsShown() and scroll:GetVerticalScroll()==0,"shrinking reuses/clears overflow controls and restores original single-item geometry")
        if n==500 then
            local native=env.CreateFrame("Frame",nil,env.UIParent)
            env.ProfessionsFrame=native
            local badge=F.icons[1]
            st.state=State("craft",1);F.Refresh()
            CheckDock(f,badge,native,native,"TOPRIGHT","TOPRIGHT")
            check(not bar:IsShown() and not scroll.wheel and badge.enabled,
                "the dock retires the previous vendor viewport and leaves the one craft badge usable")
            st.state=State("vendor",n);st.context.vendor=true;F.Refresh()
            check(f.parent==env.UIParent and f.scroll==scroll and f.content.parent==scroll
                and F.icons[1]==badge and bar:IsShown() and scroll.wheel and F.icons[1].enabled,
                "a later overflowing vendor stage recovers its viewport and original pooled badge")
            native:Hide()
        end
        st.state=State("vendor",n);st.context.vendor=true;F.Refresh()
        env.UIParent:SetSize(400,300);st.emit("DISPLAY_SIZE_CHANGED")
        check(f.width<=368 and f.height<=268 and f.overflow and f.label.point[5]==-f.viewportHeight,"display resize recomputes bounded viewport and leaves caption outside it")
        env.UIParent:SetSize(800,600);st.emit("UI_SCALE_CHANGED")
        check(f.width<=768 and f.height<=568 and f.itemCount==n,"UI scale lifecycle restores bounds without truncating the item pool")
        st.combat=true;st.emit("PLAYER_REGEN_DISABLED")
        check(not f:IsShown() and not bar:IsShown() and not scroll.wheel and st.glows()==0,"combat retires overflow controls and every visible proc effect")
        st.combat=false;st.emit("PLAYER_REGEN_ENABLED");st.state=nil;F.Refresh()
        check(not st.handlers.DISPLAY_SIZE_CHANGED and not st.handlers.UI_SCALE_CHANGED and st.glows()==0,"completion removes dynamic display watchers and leaves no effect owner")
    end
end
do
    local F,st=Fixture(true)
    st.state={kind="mail",quantity=2,name="Charged oil",items={[300]=2},chargesPerItem=5};F.Refresh()
    check(F.icons[1].count.text=="2","mail badges stay physical counts without multiplying item charges again")
    st.state={kind="vendor",quantity=8,items={[2321]=6,[2605]=2},vendorProvider={}}
    st.nameOverrides[2321],st.nameOverrides[2605]="Fine Thread","Green Dye"
    F.Refresh()
    check(F.frame.label.text=="Get 6 × Fine Thread\n2 × Green Dye" and F.icons[1].disabledMotion
        and F.icons[2].count.text=="2" and not F.icons[2].enabled,
        "the passive vendor reminder names both combined material quantities")
    F.icons[2]:Fire("OnEnter")
    check(st.tipLines[1]=="2 Green Dye" and st.tipLines[4]=="Visit a vendor selling the queued materials.",
        "a pending vendor item can show its own quantity and the companion instructions")
    st.state.items[2605],st.state.quantity=nil,6
    F.Refresh()
    check(F.frame.label.text=="Get 6 × Fine Thread","the single-material reminder names its exact remaining amount")
    st.state=State("vendor",2);st.context.vendor=true;F.Refresh();st.press(1)
    check(F.icons[1].width==40 and F.icons[2].width==40 and not F.frame.scripts.OnClick,"two normal item buttons remain independently pressable and panel stays inert")
end
do
    local F,st,env=Fixture(true)
    env.FluxItemClass.GetName=function() return "Green Silk Pack" end
    env.ProfessionsFrame=env.CreateFrame("Frame",nil,env.UIParent)
    st.state={kind="craft",name="Green Silk Pack",quantity=2,items={[5764]=2},
        logistics={resume="stopped:2",carriedOutput=2,remainingOutput=2}}
    F.GetProfessionWindowAction=function() return st.state end
    F.Refresh()
    CheckDock(F.frame,F.icons[1],env.ProfessionsFrame,env.ProfessionsFrame,"TOPRIGHT","TOPRIGHT")
    check(F.frame.label.text=="Resume 2 × Green Silk Pack" and F.icons[1].count.text=="2" and not st.windowButton,
        "the companion resume carries its full information into the existing profession window")
    F.icons[1]:Fire("OnEnter")
    check(st.tipLines[4]=="Count 2 carried and continue 2.",
        "the reminder explains what the exact carry confirmation and next batch will do")
end
do
    local F,st,env=Fixture(false,false)
    st.state=State("bank",2);st.context.bank=true;F.Refresh()
    check(F.frame and not F.frame:IsShown() and not F.icons[1].enabled,"missing HUD anchor hides all ordinary item input")
    st.hud();st.emit("PLAYER_LOGIN")
    check(F.frame:IsShown() and F.frame.point[2]==st.window and F.frame.point[4]==-66 and F.frame.point[5]==26
        and F.icons[2].enabled,"late HUD initialization restores the adjusted fallback anchor and item buttons")
    env.FluxExtraAbilityHost={native=true};env.FluxWindowFrame:SetOffset()
    check(F.frame.point[2]==env.FluxExtraAbilityHost and F.frame.point[4]==16 and F.frame.point[5]==-68 and st.clicks==0,
        "late native host becomes preferred at its adjusted offset without an item action")
end
do
    local F,st,env=Fixture(false,false)
    local native=env.CreateFrame("Frame",nil,env.UIParent)
    env.ProfessionsFrame=native
    st.state=State("craft",1);F.Refresh()
    CheckDock(F.frame,F.icons[1],native,native,"TOPRIGHT","TOPRIGHT")
    check(F.icons[1].enabled, "an open profession can host a ready craft before either optional HUD anchor exists")
    native:Hide()
    check(not F.frame:IsVisible() and not F.icons[1].enabled,
        "closing the profession with no HUD anchor retires the widget and its click")
end
do
    local F,st=Fixture(true)
    st.context.profession=true
    st.state={kind="profession",name="Tailoring",quantity=6,items={[200]=6}};F.Refresh()
    local badge=F.icons[1]
    badge:Fire("OnEnter")
    check(F.frame.label.text=="OPEN Tailoring" and badge.icon.texture==9200 and badge.count.text=="6"
        and st.tipLines[1]=="6 Item200" and st.tipLines[4]=="Open the profession before crafting.",
        "opening displays the profession by name while retaining the planned output icon and quantity")
    st.press(1)
    check(st.clicks==1 and st.actions[1][200]==6 and badge.enabled and st.glows()==1,
        "the ready profession opener uses only the existing physical action path and private proc")
    st.blocked=true;F.Refresh();st.press(1)
    check(st.clicks==1 and not badge.enabled and st.glows()==0,"a blocked opener immediately loses its click and proc")
    st.blocked=false
    st.state={kind="craft",name="Bandage",quantity=2,itemID=200,items={},task={parentID=200,operations=2,yield=3}};F.Refresh()
    check(F.icons[1]==badge and F.frame.label.text=="CRAFT 2 Bandage" and badge.enabled and st.glows()==1
        and badge.count.text=="6","the same pooled badge switches from opening to crafting with its current proc")
    st.state.nativeCraft=true;F.Refresh();badge:Fire("OnEnter")
    check(F.frame.label.text=="Open recipe: Bandage" and badge.count.text=="6" and badge.enabled
        and st.tipLines[2]=="Open recipe: Bandage" and st.tipLines[4]=="Press to reveal the exact recipe, then use Create in the profession window.",
        "native craft guidance identifies the exact recipe and keeps the separate planned output count")
    st.state.nativeCraftOperations=2;F.Refresh()
    check(st.tipLines[1]=="6 Item200" and st.tipLines[4]=="Press to reveal the exact recipe. Use Create in the profession window with quantity 2.",
        "the tooltip guides native Create using operations while the item badge retains six outputs")
    st.state.nativeCraftOperations=1;F.Refresh()
    check(st.tipLines[4]=="Press to reveal the exact recipe. Use Create in the profession window with quantity 1.",
        "the visible tooltip updates when the planned operations change by themselves")
    local before=st.clicks
    st.state.nativeCraftOperations=2;st.state.nativeCraftPrepared=1;F.Refresh();st.press(1)
    check(F.frame.label.text=="Click Blizzard Create (1)" and badge.count.text=="6"
        and st.tipLines[4]=="Quantity 1 is set. Click Create at the bottom of Blizzard's profession window."
        and not badge.enabled and st.glows()==0 and st.clicks==before,
        "prepared owner work points to Blizzard Create and drops its action and glow")
    st.state.logistics={};st.state.nativeCraftPrepared=2;F.Refresh();st.press(1)
    check(F.frame.label.text=="Click Blizzard Create (2)" and badge.count.text=="6"
        and st.tipLines[4]=="Quantity 2 is set. Click Create at the bottom of Blizzard's profession window."
        and not badge.enabled and st.glows()==0 and st.clicks==before,
        "prepared companion work shows its exact amount without an action or glow")
    st.state.nativeCraftPrepared=nil;F.Refresh();st.press(1)
    check(F.frame.label.text=="Open recipe: Bandage" and badge.enabled and st.glows()==1 and st.clicks==before+1
        and st.tipLines[4]=="Press to reveal the exact recipe. Use Create in the profession window with quantity 2.",
        "an unprepared companion recipe still uses the normal HUD action")
    st.state.logistics=nil;st.state.nativeCraftPrepared=0;F.Refresh()
    check(F.frame.label.text=="Open recipe: Bandage","an invalid prepared count keeps the recipe-opening action")
    st.state.nativeCraftOperations=0;F.Refresh()
    check(st.tipLines[4]=="Press to reveal the exact recipe, then use Create in the profession window.",
        "an unavailable operation count uses the ordinary native craft help")
    before=st.clicks;st.press(1)
    check(st.clicks==before+1,"the native craft affordance remains on the ordinary released-item action")
    st.state.kind,st.state.quantity,st.state.items="crafting",1,{[200]=3};F.Refresh()
    check(not F.icons[1].enabled and st.glows()==0 and F.icons[1].count.text=="3" and F.frame.label.text=="CRAFTING 1 Bandage",
        "produced craft outputs update the remaining badge/caption while busy input and effects stay off")
    st.state.kind,st.state.items="craft",{};st.craftReady=false;F.Refresh()
    check(not F.icons[1].enabled and st.glows()==0,"an unavailable profession click cannot imply usable proc art")
end
do
    local F,st,env=Fixture(true)
    local attached, armedSpell, owner, options = 0
    st.flux.SecureClickProxy={
        Attach=function(slot, opts)
            check(slot==F.icons[1] and slot:GetFrameStrata()=="HIGH" and opts.clicks=="LeftButtonUp",
                "the secure opener uses the raised first badge geometry for a direct release")
            attached, owner, options = attached+1, slot, opts
        end,
        Refresh=function(slot)
            check(slot==owner,"only the attached badge's proxy is refreshed")
            armedSpell=options.enabled() and options.spell() or nil
        end,
    }
    st.state=State("mail",1);st.context.mail=true;F.Refresh()
    check(attached==0 and not armedSpell,"ordinary follow-up work never creates a secure profession region")
    st.context.profession=true
    st.state={kind="profession",name="Tailoring",quantity=6,items={[200]=6},profession={spellID=3908}};F.Refresh()
    check(attached==1 and armedSpell==3908 and F.icons[1].enabled,"opening arms the one owned profession spell on the visible first badge")
    st.state.profession.spellID=2018;F.Refresh()
    check(attached==1 and armedSpell==2018,"repainting the action updates the attached spell without a second proxy")
    local native=env.CreateFrame("Frame",nil,env.UIParent)
    env.ProfessionsFrame=native
    F.RefreshProfessionLayer()
    check(F.frame.parent==native and attached==1 and armedSpell==2018 and owner==F.icons[1],
        "the existing secure proxy follows its docked opener without creating another secure region")
    native:Hide()
    check(F.frame.parent==env.UIParent and attached==1 and armedSpell==2018,
        "the same secure proxy follows the opener back to the floating HUD")
    st.blocked=true;F.Refresh()
    check(not armedSpell and not F.icons[1].enabled,"loss of stage readiness immediately disarms the attached profession click")
    st.blocked=false;F.Refresh()
    st.state.kind="craft";F.Refresh()
    check(not armedSpell and F.icons[1].enabled,"crafting recycles the badge without retaining the profession click")
    st.state.kind="profession";F.Refresh()
    st.combat=true;st.emit("PLAYER_REGEN_DISABLED")
    check(not armedSpell and not F.frame:IsShown(),"combat hide retires the attached secure profession region")
    st.combat=false;st.emit("PLAYER_REGEN_ENABLED")
    check(attached==1 and armedSpell==2018,"combat exit reuses and refreshes the profession region")
    st.state=nil;F.Refresh()
    check(not armedSpell and not F.frame:IsShown(),"work completion retires the first badge's secure click")
end
for _,classic in ipairs({false,true}) do
    local F,st=Fixture(true);st.atlas["UI-HUD-ActionBar-Proc-Loop-Flipbook"]=false;st.classicLoaded=classic
    st.state=State("mail",1);st.context.mail=true;F.Refresh()
    check(st.glows()==1 and st.styles[F.icons[1]]==(classic and "classic" or "button"),"missing modern artwork falls back only on the private usable item")
    st.blocked=true;F.Refresh()
    check(F.frame:IsShown() and st.glows()==0 and not F.icons[1].enabled,"a visible disabled item releases either renderer's private fade immediately")
    st.blocked=false;F.Refresh()
    st.state=State("mail",2);F.Refresh()
    local overlay=F.icons[1].__LBGoverlay or F.icons[1]._ButtonGlow
    check(overlay.width==40*1.4 and overlay.height==40*1.4,"fallback shrink replaces the retained fading geometry immediately")
    st.state=State("mail",1);F.Refresh()
    check(st.glows()==1 and F.icons[1].width==44,"classic/private art survives adaptive icon shrink and regrowth without stale sibling effects")
    overlay=F.icons[1].__LBGoverlay or F.icons[1]._ButtonGlow
    check(overlay.width==44*1.4 and overlay.height==44*1.4,"fallback regrowth measures only the resized current item")
    st.state=nil;F.Refresh();check(st.glows()==0,"completion retires every classic or modern art owner")
end
do
    local F,st=Fixture(true);st.noLCG=true;st.state=State("mail",1);st.context.mail=true;F.Refresh()
    check(F.icons[1].enabled and st.glows()==0,"missing optional artwork never disables an otherwise usable restock item")
    st.noLCG=false;F.Refresh();check(st.glows()==1,"late optional artwork appears on an existing owner refresh")
end
do
    local F,st=Fixture(true);st.noLCG=true;st.classicLoaded=true;st.state=State("mail",1);st.context.mail=true;F.Refresh()
    check(st.styles[F.button]=="classic","late modern artwork starts with the available private classic fallback")
    st.noLCG=false;F.Refresh()
    check(st.styles[F.button]=="proc" and st.glows()==1,"late modern artwork replaces a currently active private fallback without hiding its item")
    local G,other=Fixture(true);other.atlas["UI-HUD-ActionBar-Proc-Loop-Flipbook"]=false;other.state=State("mail",1);other.context.mail=true;G.Refresh()
    other.atlas["UI-HUD-ActionBar-Proc-Loop-Flipbook"]=true;G.Refresh()
    check(other.styles[G.button]=="proc" and G.frame:IsShown(),"late central atlas availability upgrades the existing fallback owner")
end
print(("Auction restock per-item follow-up UI: %d checks PASS; %d client profiles plus193/500/1000 overflow; native pixels/clipping/input/controller/taint NOT RUN"):format(checks,profiles))
