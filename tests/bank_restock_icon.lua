-- Real merchant factory + bank module; geometry/lifecycle model, not native pixels.
local root = arg[1] or "."
local checks = 0
local function check(ok, message) assert(ok, message); checks = checks + 1 end
local function read(path)
    local f = assert(io.open(root .. "/" .. path, "rb"))
    local source = f:read("*a"); f:close(); return source
end
for _, family in ipairs({ "retail", "forever", "era", "anniversary", "classic" }) do
 for _, alternate in ipairs({ false, true }) do
  for _, merchantReady in ipairs({ false, true }) do
   for _, directEvents in ipairs({ false, true }) do
    local env = setmetatable({}, { __index = _G }); env._G = env
    local frames, timers, callbacks = {}, {}, {}
    local methods = {}
    function methods:SetSize(w, h) self.w, self.h = w, h end
    function methods:GetSize() return self.w or 0, self.h or 0 end
    function methods:GetWidth() return self.w or 0 end
    function methods:SetWidth(w) self.w = w end
    function methods:GetRight() return self.right or self:GetWidth() end
    function methods:GetHeight() return self.h or 0 end
    function methods:SetHeight(h) self.h = h end
    function methods:SetText(text) self.text = text end
    function methods:SetScale(scale) self.scale = scale end
    function methods:GetScale() return self.scale or 1 end
    function methods:SetPoint(...) self.points[#self.points + 1] = { ... } end
    function methods:GetPoint(i) return table.unpack(self.points[i]) end
    function methods:GetNumPoints() return #self.points end
    function methods:ClearAllPoints() self.points = {}; self.allPoints = nil end
    function methods:SetAllPoints(other) self.allPoints = other end
    function methods:SetParent(parent) self.parent = parent end
    function methods:GetParent() return self.parent end
    function methods:GetRegions() return end
    function methods:GetDrawLayer() return self.layer end
    function methods:SetTexture(texture) self.texture = texture end
    function methods:GetTexture() return self.texture end
    function methods:SetTexCoord(...) self.coords = { ... } end
    function methods:GetTexCoord() return table.unpack(self.coords or {0,1,0,1}) end
    function methods:SetDesaturated(on) self.desaturated = on end
    function methods:SetFrameLevel(level) self.level = level end
    function methods:GetFrameLevel() return self.level or 1 end
    function methods:SetFrameStrata(strata) self.strata = strata end
    function methods:GetFrameStrata() return self.strata or "HIGH" end
    function methods:Show() self.shown = true end
    function methods:Hide() self.shown = false; if self.hooks and self.hooks.OnHide then self.hooks.OnHide(self) end end
    function methods:IsShown() return self.shown ~= false end
    function methods:IsVisible() return self:IsShown() and (not self.parent or self.parent:IsVisible()) end
    function methods:IsEnabled() return self.enabled ~= false end
    function methods:SetChecked(checked) self.checked = checked end
    function methods:Enable() self.enabled = true end
    function methods:Disable() self.enabled = false end
    function methods:SetScript(key, fn) self.scripts[key] = fn end
    function methods:HookScript(key, fn) self.hooks=self.hooks or {};self.hooks[key]=fn end
    function methods:RegisterEvent() end
    function methods:RegisterForClicks() end
    function methods:RegisterForDrag() end
    function methods:SetPropagateMouseClicks() end
    function methods:SetPropagateMouseMotion() end
    local function object(parent, layer)
        return setmetatable({parent=parent, layer=layer, points={}, scripts={}}, {__index=methods})
    end
    function methods:CreateTexture(_, layer) return object(self, layer) end
    function methods:CreateFontString(_, layer) return object(self, layer) end
    for _, state in ipairs({"Normal", "Highlight", "Pushed", "Checked", "DisabledChecked"}) do
        methods["Set" .. state .. "Texture"] = function(self, texture)
            self[state] = object(self); self[state]:SetTexture(texture)
        end
        methods["Get" .. state .. "Texture"] = function(self) return self[state] end
    end
    env.CreateFrame = function(_, name, parent)
        local frame = object(parent); frames[#frames+1] = frame
        if name then env[name] = frame end
        return frame
    end
    env.UIParent = object()
    env.UIParent:SetSize(1920,768)
    env.FLUX_API = {isPreDF=family~="retail" and family~="forever", isForever=family=="forever",
        UseLegacyBankSlotsUI=function() return family~="retail" end}
    env.Flux = {Inventory={SetBaganatorBankLive=function() end}}
    local nativeEvents={}
    if directEvents then
        env.Flux.Events={Register=function(name,fn) nativeEvents[name]=fn;return true end}
    end
    env.FluxUI_UsesAlternativeBagUI = function() return alternate end
    env.C_Timer = {After=function(delay, fn) timers[#timers+1] = fn end}
    env.FluxRestock = {Inv={Bank={RegisterBankOpen=function(_,fn) callbacks.open=fn end,
        RegisterBankClose=function(_,fn) callbacks.close=fn end}}}
    env.FluxBankRestock = {IsAutoEnabled=function() return true end, GetCachedCanRunNow=function() return true end}
    env.BankFrame = object(env.UIParent)
    env.BankFrame:SetFrameStrata("MEDIUM")
    env.BankFrame.BankItemSearchBox = object(env.BankFrame)
    env.BankFrame.BankItemSearchBox:SetSize(110,20)
    env.BankFrame.BankItemSearchBox:SetFrameLevel(800)
    env.BankFrame.BankPanel=object(env.BankFrame);env.BankFrame.BankPanel:SetFrameLevel(900)
    env.BankFrame.BankPanel:SetFrameStrata(merchantReady and "DIALOG" or "MEDIUM")
    env.BankFrame.CloseButton=object(env.BankFrame);env.BankFrame.CloseButton:SetFrameLevel(950)
    env.MerchantRepairAllButton = object(env.UIParent); env.MerchantRepairAllButton:SetSize(36,36)
    -- Small native repair icon reproduces the non-Classic copy path. The Classic
    -- branch has its own fixed icon size, also stale after a Baganator resize.
    if merchantReady then
        local icon = object(env.MerchantRepairAllButton)
        icon:SetSize(16,16); icon:SetPoint("TOPLEFT",env.MerchantRepairAllButton,"TOPLEFT",0,0)
        env.MerchantRepairAllButton.Icon = icon
    end
    assert(load(read("Inventory/Restock/Vendor/FluxVendorAutoMerchantUI.lua"),"merchant","t",env))("_FluxUI",{})
    local button = assert(load(read("Inventory/Restock/Bank/FluxBankRestockButton.lua"),"bank","t",env))()
    local bankButton
    for _,frame in ipairs(frames) do if frame.Icon then bankButton=frame end end
    check(bankButton ~= nil, family.." creates restock button")
    if button.GetControl then check(button.GetControl()==bankButton,"public diagnostic resolves actual owned control") end
    local function OpenUI()
        callbacks.open()
        if directEvents then nativeEvents.BANKFRAME_OPENED() end
    end
    local function CloseUI()
        callbacks.close()
        if directEvents then nativeEvents.BANKFRAME_CLOSED() end
    end
    local function iconFits()
        local icon = bankButton.Icon
        check(#icon.points==2 and icon.allPoints==nil, family.." icon has two local anchors")
        local a,b=icon.points[1],icon.points[2]
        check(a[1]=="TOPLEFT" and a[2]==bankButton and a[3]=="TOPLEFT" and a[4]==1 and a[5]==-1,"icon top inset")
        check(b[1]=="BOTTOMRIGHT" and b[2]==bankButton and b[3]=="BOTTOMRIGHT" and b[4]==-1 and b[5]==1,"icon bottom inset")
        check(icon.texture=="Interface/Icons/INV_Misc_Bag_08","restock artwork retained")
    end
    iconFits()
    local view = object(env.UIParent)
    view:SetSize(500,400)
    view.currentTab=object(view); view.currentTab:SetSize(500,400)
    view.currentTab.ScrollBox=object(view.currentTab); view.currentTab.ScrollBox:SetSize(480,300)
    env.ScrollBoxConstants={UpdateImmediately=1}
    function view.currentTab.ScrollBox:FullUpdate(mode) check(mode==1,"native viewport recomputed immediately") end
    view.TransferButton = object(view); view.TransferButton:SetSize(32,22)
    env.FluxBaganatorCompat = {GetActiveBaganatorBankView=function() return view end}
    if family=="era" or family=="anniversary" then env.FluxCombinedBank=object(env.UIParent) end
    OpenUI()
    check(#timers==2,"open reuses bounded attach retries")
    for _,fn in ipairs(timers) do fn() end
    check(bankButton:IsShown(),"restock visible with/without bag addon")
    if alternate then
        check(bankButton.parent==view and bankButton.w*bankButton:GetScale()==36
            and bankButton.h*bankButton:GetScale()==36,"Baganator full-size button inside view")
        check(view:GetHeight()==448 and view.currentTab:GetHeight()==400,"dedicated footer below unchanged native tab")
        local anchor=bankButton.points[1]
        check(anchor[1]=="BOTTOMRIGHT" and anchor[2]==view and anchor[3]=="BOTTOMRIGHT"
            and anchor[4]<0 and anchor[5]>=0,"restock stays inside footer")
        check(bankButton.w==36 and bankButton.h==36,"merchant art retains its designed coordinate space")
        if bankButton.fluxEmptySlot then
            check(bankButton.fluxEmptySlot.w==64 and bankButton.fluxEmptySlot.h==64,
                "fixed merchant background scales with whole button")
        end
        view.TransferButton:SetSize(32,32); button.AttachToBaganatorBank(view)
        check(bankButton.w*bankButton:GetScale()==36 and view:GetHeight()==448,"toolbar change cannot shrink or accumulate footer")
        view.TransferButton:SetSize(16,24); button.AttachToBaganatorBank(view)
        check(bankButton.w*bankButton:GetScale()==36 and bankButton.h*bankButton:GetScale()==36,
            "narrow toolbar keeps full-sized restock control")
        view.TransferButton=nil; view.SortButton=object(view); view.SortButton:SetSize(32,22)
        button.AttachToBaganatorBank(view)
        check(bankButton.w*bankButton:GetScale()==36,"missing transfer keeps full size")
        button.ReleaseBaganatorFooter(view)
        check(view:GetHeight()==400,"footer release restores native height")
        view.currentTab.ScrollBar=object(view.currentTab); view.currentTab.ScrollBar.right=516
        view.currentTab:SetHeight(760); view:SetHeight(760); view.currentTab.ScrollBox:SetHeight(650)
        button.AttachToBaganatorBank(view)
        check(view:GetHeight()==768 and view.currentTab:GetHeight()==720,"tall bank fits screen with footer")
        check(view.currentTab.ScrollBox:GetHeight()==610,"tall bank shrinks existing viewport without covering items")
        check(view:GetWidth()==524 and view.currentTab:GetWidth()==524,"new scrollbar stays inside enlarged bank width")
        button.AttachToBaganatorBank(view)
        check(view:GetHeight()==768 and view.currentTab.ScrollBox:GetHeight()==610,"repeated tall layout is idempotent")
        -- Replay the existing compat wrappers against Baganator's real ordering:
        -- UpdateTransferButton attaches, then OnTabFinished overwrites outer size.
        view.UpdateTransferButton=function() end
        view.OnTabFinished=function(self) self:UpdateTransferButton(); self:SetSize(self.currentTab:GetSize()) end
        env.Baganator_SingleViewBankViewFrameblizzard=view
        assert(load(read("BaganatorCompat/FluxBaganator_BankRestock.lua"),"baganator compat","t",env))()
        env.FluxBaganatorCompat.FinalizeBankRestock()
        for i=1,3 do view:OnTabFinished() end
        check(view:GetHeight()==768 and view.currentTab:GetHeight()==720,"native completion wrappers do not accumulate footer or viewport shrink")
        view.currentTab.isLocked=true; button.AttachToBaganatorBank(view)
        check(not bankButton:IsShown() and view:GetHeight()==760,"locked tab releases footer and hides button")
        view.currentTab.isLocked=false; button.AttachToBaganatorBank(view)
        view:Hide(); env.FluxBaganatorCompat.GetActiveBaganatorBankView=function() return nil end
        env.FluxUI_UsesAlternativeBagUI=function() return false end
        button.AttachToBank()
        check(bankButton:GetScale()==1,"native/combined handoff restores unscaled size")
        check(view:GetHeight()==760 and view.currentTab:GetHeight()==760 and view.currentTab.ScrollBox:GetHeight()==650,
            "native handoff restores all owned Baganator geometry")
        check(view:GetWidth()==500 and view.currentTab:GetWidth()==500,"native handoff restores temporary scrollbar width")
    elseif family=="forever" then
        check(bankButton.parent==env.BankFrame,"Forever control inherits native bank visibility/scale/movement")
        local p=bankButton.points[1]
        check(p[1]=="RIGHT" and p[2]==env.BankFrame.BankItemSearchBox and p[3]=="LEFT" and p[4]<0 and p[5]==0,
            "Forever button inside header left of search")
        env.BankItemSearchBox=env.BankFrame.BankItemSearchBox; env.BankFrame.BankItemSearchBox=nil
        button.AttachToBank()
        check(bankButton.points[1][2]==env.BankItemSearchBox,"global search-box fallback")
    else
        check(bankButton.parent==(env.FluxCombinedBank or env.BankFrame),"native/combined placement retained")
    end
    if bankButton:GetParent()==env.BankFrame then
        check(bankButton:GetFrameStrata()==(merchantReady and "DIALOG" or "HIGH") and bankButton:GetFrameLevel()>=955,
            "native control draws above high-level bank chrome and content")
    end
    iconFits()
    button.Refresh(); check(bankButton:IsEnabled(),"manual restock enabled")
    check(bankButton.scripts.OnClick and bankButton.scripts.OnReceiveDrag and bankButton.scripts.OnEnter,"click/drop/tooltip retained")
    local parent=bankButton:GetParent()
    parent:Hide()
    check(not bankButton:IsVisible(),"native parent hide immediately hides restock without a callback")
    parent:Show()
    check(bankButton:IsVisible(),"native parent show restores attached restock")
    CloseUI()
    for _,fn in ipairs(timers) do fn() end
    check(not bankButton:IsShown(),"cancelled delayed open retries cannot resurrect button after close")
    OpenUI()
    for _,fn in ipairs(timers) do fn() end
    check(bankButton:IsVisible(),"reopening attaches again after cancelled retries")
    parent:Hide();env.BankFrame:Hide();button.AttachToBank()
    check(not bankButton:IsShown(),"hidden bank refuses explicit/late attachment")
    parent:Show();env.BankFrame:Show();button.AttachToBank()
    check(bankButton:IsVisible(),"visible bank reattaches in original location")
    local hiddenHost=object(env.UIParent);hiddenHost:Hide()
    parent:SetParent(hiddenHost);env.BankFrame:SetParent(hiddenHost)
    button.AttachToBank()
    check(not bankButton:IsShown(),"shown bank under hidden owner refuses attachment")
    parent:SetParent(env.UIParent);env.BankFrame:SetParent(env.UIParent);button.AttachToBank()
    check(bankButton:IsVisible(),"restored native owner reattaches button")
    if directEvents then
        -- The inventory adapter may keep its latch open and suppress close.
        -- Native UI closes independently even while every frame still reports shown.
        nativeEvents.BANKFRAME_CLOSED()
        check(not bankButton:IsShown(),"raw native close hides control without inventory close callback")
        callbacks.open();button.AttachToBank()
        check(not bankButton:IsShown(),"stale inventory-open/manual attach cannot resurrect closed native UI")
        nativeEvents.BANKFRAME_OPENED()
        for _,fn in ipairs(timers) do fn() end
        check(bankButton:IsVisible(),"next real bank open restores control")
    end
    CloseUI(); check(not bankButton:IsShown(),"bank close hides owned control")
   end
  end
 end
end
print(string.format("bank restock icon: %d checks passed (five clients; native/Baganator; cold/warm merchant)",checks))
