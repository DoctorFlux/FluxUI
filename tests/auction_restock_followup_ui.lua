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
        check(ev=="OnVerticalScroll", "only the viewport's native vertical-scroll path gains an additive hook")
        local previous=self.scripts[ev]; self.scripts[ev]=function(self,...) if previous then previous(self,...) end;fn(self,...) end
    end
    function m:Hide() local old=self.shown;self.shown=false;if old then self:Fire("OnHide") end end
    function m:Show() self.shown=true end
    function m:IsShown() return self.shown end
    function m:SetEnabled(v) self.enabled=v end
    function m:EnableMouse(v) self.mouse=v end
    function m:EnableMouseWheel(v) self.wheel=v end
    function m:SetParent(v) self.parent=v end
    function m:GetName() return self.name end
    function m:SetPoint(...) self.point={...};self.points[#self.points+1]=self.point end
    function m:ClearAllPoints() self.points={} end
    function m:Range()
        if self.kind=="ScrollFrame" and self.scrollChild then self:Fire("OnScrollRangeChanged",0,math.max(0,(self.scrollChild.height or 0)-(self.height or 0)))
        elseif self.parent and self.parent.kind=="ScrollFrame" then self.parent:Range() end
    end
    function m:SetSize(w,h) self.width,self.height=w,h;self:Range() end
    function m:GetSize() return self.width,self.height end
    function m:GetWidth() return self.width end
    function m:GetHeight() return self.height end
    function m:SetFrameLevel(v) self.level=v end
    function m:SetFrameStrata(v) self.strata=v end
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
    for _,key in ipairs({"SetPoint","ClearAllPoints","SetSize","SetFont","SetTexture","SetText","Show","Hide","SetEnabled","EnableMouseWheel"}) do
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
        check(not template or template=="UIPanelScrollFrameTemplate","HUD owns no secure template or native action button")
        check(kind=="Frame" or kind=="Button" or kind=="ScrollFrame","HUD creates only ordinary frames, buttons and viewport")
        st.frames=st.frames+1;if kind=="Button" then st.buttons=st.buttons+1 end
        local f=widget(kind,parent);f.name,f.template=name,template;if name then check(not env[name],"dedicated frame names are immutable");env[name]=f end
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
            Start(slot,"proc");slot._ProcGlowFluxRestockFollowup=widget("Frame",slot)
            slot._ProcGlowFluxRestockFollowup.width,slot._ProcGlowFluxRestockFollowup.height=slot.width*1.4,slot.height*1.4
        end,
        ProcGlow_Stop=function(slot,key) check(key=="FluxRestockFollowup","proc cleanup retains its private key");Stop(slot,"proc");slot._ProcGlowFluxRestockFollowup=nil end,
        ButtonGlow_Start=function(slot) Start(slot,"button");slot._ButtonGlow=widget("Frame",slot) end,
        ButtonGlow_Stop=function(slot) Stop(slot,"button");slot._ButtonGlow=nil end,
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
    F.Click=function(...)
        check(select("#",...)==0 and st.hardware and not st.combat,"every item dispatches the same no-ID whole-stage intent from a fresh press")
        local action={};for id,q in pairs(st.state.items or {}) do action[id]=q end
        st.clicks=st.clicks+1;st.actions[st.clicks]=action
    end
    env.FluxAuctionRestock={Followup=F}
    local L={AH_TITLE="Restock",AH_FOLLOWUP_HELP="This restock only.",AH_FOLLOWUP_ITEM="%d %s"}
    for _,kind in ipairs({"MAIL","BANK","VENDOR","CRAFT","CRAFTING","WAITING"}) do L["AH_FOLLOWUP_"..kind]=kind.." %d %s" end
    local events={Register=function(ev,fn) check(not st.handlers[ev],"UI event has one owned listener");st.handlers[ev]=fn end,
        Unregister=function(ev,fn) check(st.handlers[ev]==fn,"owned size listener is retired without removing another callback");st.handlers[ev]=nil end}
    local cap={HasAtlas=function(name)
        st.work.AtlasLookup=(st.work.AtlasLookup or 0)+1
        check(name=="UI-HUD-ActionBar-Proc-Start-Flipbook" or name=="UI-HUD-ActionBar-Proc-Loop-Flipbook","proc artwork checks both central atlas capabilities")
        return st.atlas[name]~=false
    end}
    local path=os.getenv("FLUX_FOLLOWUP_UI_SOURCE") or root.."/Inventory/Restock/Auction/FluxAuctionRestockFollowupUI.lua"
    local chunk=assert(loadfile(path,"t",env));if setfenv then setfenv(chunk,env) end
    chunk("_FluxUI",{Flux={Events=events,Capabilities=cap},FluxOptionsLocale=L})
    function st.emit(ev) if st.handlers[ev] then st.handlers[ev]() end end
    function st.press(index)
        local slot=F.icons[index or 1]
        if not F.frame or not F.frame:IsShown() or not slot or not slot:IsShown() or not slot.enabled then return end
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
            check(slot._ProcGlowFluxRestockFollowup.width==slot.width*1.4,"active private proc geometry follows adaptive item size")
        end
        if i>1 then
            local prev=F.icons[i-1]
            check(slot.y==prev.y and slot.x-prev.x-prev.size==1 or slot.y-prev.y-prev.size==1,
                "neighboring item button rectangles have exactly one pixel of horizontal or vertical gap")
        end
    end
end
for _,client in ipairs({"Retail","Forever","MoP","Era","Anniversary"}) do
    profiles=profiles+1
    local F,st,env=Fixture(client=="Retail" or client=="Forever")
    F.Paint(nil);st.state=State("waiting",2);F.Refresh();check(st.frames==0,"waiting never allocates question-mark HUD or focus targets")
    st.state=State("mail",2);st.combat=true;F.Refresh();check(st.frames==0,"new work in combat allocates no buttons or decorations")
    st.combat=false;st.context.mail=true;st.emit("PLAYER_REGEN_ENABLED");CheckItems(F,2)
    check(env.FluxAuctionRestockFollowupButton==F.button and F.button.name=="FluxAuctionRestockFollowupButton",
        "the first real item button preserves its existing named binding/macro target")
    check(F.frame.width==196 and F.frame.height==88 and st.buttons==2,"two-item appearance retains the existing compact geometry")
    local before=st.clicks
    F.icons[2]:Fire("OnEnter");check(st.tip and st.tipOwner==F.icons[2] and st.tipLines[1]=="3 Item1002"
        and st.tipLines[2]=="MAIL 5 Restock" and #st.tipLines==3,"each icon owns a bounded tooltip for its own quantity/name and current stage")
    st.press(2);check(st.clicks==before+1 and st.actions[st.clicks][1001]==2 and st.actions[st.clicks][1002]==3,"pressing the second real item handles the complete current stage")
    for _,kind in ipairs({"mail","bank","vendor"}) do
        st.state=State(kind,2);st.context={[kind]=true};F.Refresh();F.Refresh()
        check(F.icons[1].enabled and F.icons[2].enabled and not F.frame.scripts.OnClick and st.glows()==2,"matching usable interactions glow each ordinary item button without panel activation")
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
    st.state=State("vendor",2);st.context.vendor=true;F.Refresh();st.press(1)
    check(F.icons[1].width==40 and F.icons[2].width==40 and not F.frame.scripts.OnClick,"two normal item buttons remain independently pressable and panel stays inert")
end
do
    local F,st,env=Fixture(false,false)
    st.state=State("bank",2);st.context.bank=true;F.Refresh()
    check(F.frame and not F.frame:IsShown() and not F.icons[1].enabled,"missing HUD anchor hides all ordinary item input")
    st.hud();st.emit("PLAYER_LOGIN")
    check(F.frame:IsShown() and F.frame.point[2]==st.window and F.icons[2].enabled,"late HUD initialization restores the fallback anchor and item buttons")
    env.FluxExtraAbilityHost={native=true};env.FluxWindowFrame:SetOffset()
    check(F.frame.point[2]==env.FluxExtraAbilityHost and st.clicks==0,"late native host becomes preferred without an item action")
end
do
    local F,st=Fixture(true)
    st.state={kind="craft",name="Bandage",quantity=2,itemID=200,items={},task={parentID=200,operations=2,yield=3}};F.Refresh()
    check(F.icons[1].enabled and st.glows()==1 and F.icons[1].count.text=="6","an actionable profession-open or craft item owns its private proc effect")
    st.state.kind,st.state.quantity,st.state.items="crafting",1,{[200]=3};F.Refresh()
    check(not F.icons[1].enabled and st.glows()==0 and F.icons[1].count.text=="3" and F.frame.label.text=="CRAFTING 1 Bandage",
        "produced craft outputs update the remaining badge/caption while busy input and effects stay off")
    st.state.kind,st.state.items="craft",{};st.craftReady=false;F.Refresh()
    check(not F.icons[1].enabled and st.glows()==0,"an unavailable profession click cannot imply usable proc art")
end
for _,classic in ipairs({false,true}) do
    local F,st=Fixture(true);st.atlas["UI-HUD-ActionBar-Proc-Loop-Flipbook"]=false;st.classicLoaded=classic
    st.state=State("mail",1);st.context.mail=true;F.Refresh()
    check(st.glows()==1 and st.styles[F.icons[1]]==(classic and "classic" or "button"),"missing modern artwork falls back only on the private usable item")
    st.state=State("mail",2);F.Refresh()
    if classic then check(F.icons[1].__LBGoverlay.width==40*1.4,"classic resize replaces its retained fading geometry immediately") end
    st.state=State("mail",1);F.Refresh()
    check(st.glows()==1 and F.icons[1].width==44,"classic/private art survives adaptive icon shrink and regrowth without stale sibling effects")
    if classic then check(F.icons[1].__LBGoverlay.width==44*1.4,"a fading classic overlay is released before measuring resized item geometry") end
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
