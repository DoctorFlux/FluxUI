-- Production category selection with public native contracts and readable auras.
-- Native aura assignment, restrictions, pixels and taint require the real client.
local checks = 0
local function check(value, label) checks=checks+1; assert(value,label) end
local function RunScript(path,environment,...)
    local fn,message
    if _VERSION=="Lua 5.1" then fn,message=loadfile(path);if fn then setfenv(fn,environment)end
    else fn,message=loadfile(path,"t",environment)end
    return assert(fn,message)(...)
end
local function RunSource(text,name,environment)
    local fn,message
    if _VERSION=="Lua 5.1" then fn,message=loadstring(text,name);if fn then setfenv(fn,environment)end
    else fn,message=load(text,name,"t",environment)end
    return assert(fn,message)()
end
local function loadModule(environment)
    local fn, message
    local sourcePath=os.getenv("FLUX_RAID_AURA_SOURCE")
    if not environment.auraSource and sourcePath then
        local file=assert(io.open(sourcePath,"rb"));environment.auraSource=file:read("*a");file:close()
    end
    if environment.auraSource then
        if _VERSION=="Lua 5.1" then fn,message=loadstring(environment.auraSource);if fn then setfenv(fn,environment)end
        else fn,message=load(environment.auraSource,"@mutant-raid-auras","t",environment)end
    elseif _VERSION == "Lua 5.1" then
        fn,message=loadfile("RaidFrame/FluxRaidAuras.lua")
        if fn then setfenv(fn,environment) end
    else fn,message=loadfile("RaidFrame/FluxRaidAuras.lua","t",environment) end
    assert(fn,message)("_FluxUI",environment.addonNS or {})
    return environment.FluxRaidAuras
end

local function NativePolicy(e,client)
    local cache=os.getenv("FLUX_RAID_UPSTREAM_CACHE")
    local base=cache and cache.."/"..client.."/Interface/AddOns/" or "../__AddonsForRef/wow-ui-source-"..client.."/Interface/AddOns/"
    e.CVarCallbackRegistry={SetCVarCachable=function()end}
    e.EventRegistry={RegisterFrameEvent=function()end,RegisterCallback=function()end,RegisterFrameEventAndCallback=function()end}
    e.Enum.SpellAuraVisibilityType={RaidInCombat=1,RaidOutOfCombat=2}
    e.EnumUtil={MakeEnum=function(...)local enum={};for i,name in ipairs({...})do enum[name]=i-1 end;return enum end}
    e.securecallfunction=function(fn,...)return fn(...)end
    e.unpack=unpack or table.unpack
    for kind,rgb in pairs({MAGIC={.2,.6,1},CURSE={.6,0,1},DISEASE={.6,.4,0},POISON={0,.6,0},BLEED={1,.2,.2},NONE={.8,0,0}}) do
        e["DEBUFF_TYPE_"..kind.."_COLOR"]={GetRGBA=function()return rgb[1],rgb[2],rgb[3],1 end}
    end
    e.UnitAffectingCombat=function()return e.combat or false end
    e.UnitIsUnit=function(a,b)return a==b end
    e.UnitClass=function()return "Priest",e.playerClass or "PRIEST" end
    e.visibility,e.selfBuffs,e.priority={},{},{}
    e.C_Spell={GetVisibilityInfo=function(id)local info=e.visibility[id];if info then return info[1],info[2],info[3]end;return false,false,false end,
        IsSelfBuff=function(id)return e.selfBuffs[id]or false end,IsPriorityAura=function(id)return e.priority[id]or false end}
    local function run(path)
        local fn,message
        if _VERSION=="Lua 5.1"then fn,message=loadfile(base..path);if fn then setfenv(fn,e)end
        else fn,message=loadfile(base..path,"t",e)end
        assert(fn,message)()
    end
    run("Blizzard_FrameXMLUtil/AuraUtil.lua")
    run("Blizzard_FrameXMLUtil/"..((client=="live"or client=="forever")and"Mainline"or"Classic").."/AuraUtil.lua")
end

local function Fixture(native, failAt, source,client)
    local e=setmetatable({},{__index=_G}); e._G=e
    e.auraSource=source
    local frames,boxes={},{}
    local methods={}
    e.FluxRaidCompat={IsSecret=function(value)return type(value)=="table" and value.secret==true end}
    e.issecretvalue=e.FluxRaidCompat.IsSecret
    e.InCombatLockdown=function()return e.combat or false end
    e.UnitIsFriend=function()return true end
    e.UnitCanAttack=function()return false end
    e.raidDB={}
    e.addonNS={Flux={Client={branch=client or "forever",isAnyClassic=client=="classic"or client=="classic_era"or client=="classic_anniversary"}}}
    e.FluxOptions={GetRaidFrameDB=function()return e.raidDB end}
    e.FluxRaid_IsDispelHighlightEnabled=function()return e.dispelHighlight~=false end
    e.FluxRaidHealerExtras={GetClassBuffFilter=function()return {[1243]=true},{Fortitude=true}end}
    e.canaccesstable=function(value)return not value.secret end
    e.Enum={CustomAuraButtonDispelTypeTextureStyle={PreserveAsset=3}}
    if native then
        -- Mixin definitions stay in Blizzard's secure environment. These public
        -- exports and the registered XML template are the supported capability.
        e.CustomAuraContainerInboundMixin=false
        e.AuraContainerInbound={}
        e.CustomAuraContainerGroupDefaultOptions={}
        e.AnchorUtil={FlowDirection={Left=1,Right=2,Up=3,Down=4},FlowLayoutAxis={Horizontal=1,Vertical=2}}
        e.CustomAuraContainerAuraProcessingPolicy={ProcessAura=1}
        e.AuraContainerSortMethod={Default=0,UnitFrameDebuff=2}
    else
        e.CustomAuraContainerInboundMixin=false
        e.AuraContainerInbound=false
        e.CustomAuraContainerGroupDefaultOptions=false
        e.AnchorUtil=false
    end
    local function legal(self)
        local object=self
        while object do
            if object.nativeButton and object.nativeRestricted and e.restricted then error("native aura descendant access denied while auras are secret") end
            object=object.parent
        end
    end
    e.canaccesstable=function(value)
        local object=value
        while type(object)=="table" do
            if object.nativeButton and object.nativeRestricted and e.restricted then return false end
            object=object.parent
        end
        return true
    end
    function methods:EnableMouse(value)legal(self);self.mouse=value end
    function methods:SetSize(w,h)legal(self);self.width,self.height=w,h end
    function methods:GetWidth()legal(self);return self.width or 66 end
    function methods:GetHeight()legal(self);return self.height or 44 end
    function methods:GetSize()legal(self);return self:GetWidth(),self:GetHeight()end
    function methods:GetParent()legal(self);return self.parent end
    function methods:SetParent(parent)legal(self);self.parent=parent end
    function methods:SetWidth(value)legal(self);self.width=value end
    function methods:SetHeight(value)legal(self);self.height=value end
    function methods:SetAllPoints(value)legal(self);self.allpoints=value end
    function methods:SetPoint(...)legal(self);self.points[#self.points+1]={...}end
    function methods:ClearAllPoints()legal(self);self.points={}end
    function methods:SetTexture(value)legal(self);self.texture=value end
    function methods:SetTexCoord(...)legal(self);self.coords={...}end
    function methods:SetAtlas(value)legal(self);self.atlas=value end
    function methods:SetDesaturated(value)legal(self);self.desaturated=value end
    function methods:SetColorTexture(...)legal(self);self.color={...}end
    function methods:SetVertexColor(...)legal(self);self.color={...}end
    function methods:SetText(value)legal(self);self.text=value end
    function methods:SetAlpha(value)legal(self);self.alpha=value end
    function methods:SetScale(value)legal(self);self.scale=value end
    function methods:SetFrameLevel(value)legal(self);self.level=value end
    function methods:GetFrameLevel()legal(self);return self.level or 0 end
    function methods:SetClipsChildren(value)legal(self);self.clips=value end
    function methods:SetFont(...)legal(self);self.font={...}end
    function methods:SetFontObject(value)legal(self);self.fontObject=value end
    function methods:SetTextScale(value)legal(self);self.textScale=value end
    function methods:SetTextColor(...)legal(self);self.textColor={...}end
    function methods:SetShadowColor(...)legal(self);self.shadowColor={...}end
    function methods:SetShadowOffset(...)legal(self);self.shadowOffset={...}end
    function methods:SetWordWrap(value)legal(self);self.wordWrap=value end
    function methods:SetCooldown(start,duration)legal(self);self.start,self.duration=start,duration end
    function methods:SetHideCountdownNumbers(value)legal(self);self.hideCountdown=value end
    function methods:SetDrawSwipe(value)legal(self);self.drawSwipe=value end
    function methods:SetDrawEdge(value)legal(self);self.drawEdge=value end
    function methods:SetDrawBling(value)legal(self);self.drawBling=value end
    function methods:SetReverse(value)legal(self);self.reverse=value end
    function methods:SetSwipeColor(...)legal(self);self.swipeColor={...}end
    function methods:SetSwipeTexture(...)legal(self);self.swipeTexture={...}end
    function methods:GetCountdownFontString()legal(self);return self.countdown end
    function methods:HookScript(event,fn)self.hooks=self.hooks or {};self.hooks[event]=fn end
    function methods:Show()legal(self);local changed=not self.shown;self.shown=true;self.events=self.kind=="AuraContainer" and self.enabled==true and self.unit~="none" or false;if changed and self.hooks and self.hooks.OnShow then self.hooks.OnShow(self)end end
    function methods:Hide()legal(self);local changed=self.shown;self.shown=false;self.events=false;if changed and self.hooks and self.hooks.OnHide then self.hooks.OnHide(self)end end
    function methods:CreateAnimationGroup()
        legal(self)
        local group={owner=self,animations={},playing=false}
        self.animations=self.animations or {};self.animations[#self.animations+1]=group
        function group:SetLooping(value)self.looping=value end
        function group:Play()self.playing=true end
        function group:Stop()self.playing=false end
        function group:CreateAnimation(kind)
            local animation={kind=kind};self.animations[#self.animations+1]=animation
            for _,key in ipairs({"Target","Duration","FlipBookColumns","FlipBookRows","FlipBookFrames","FromAlpha","ToAlpha","Order"})do
                animation["Set"..key]=function(a,value)a[key]=value end
            end
            return animation
        end
        return group
    end
    if client=="forever" then function methods:AddAuraShownAnimation(group)self.shownAnimation=group end end
    function methods:SetShown(value)if value then self:Show()else self:Hide()end end
    function methods:IsShown()legal(self);return self.shown end
    function methods:IsVisible()
        legal(self)
        local parent=self
        while parent do if not parent.shown then return false end;parent=parent.parent end
        return true
    end
    function methods:SetUnit(value)self.unit=value;self.events=self.enabled==true and self.shown and value~="none" or false end
    function methods:SetEnabled(value)self.enabled=value;self.events=value==true and self.shown and self.unit~="none" or false end
    function methods:SetFlowLayoutAnchorPoint(value)self.anchor=value end
    function methods:SetFlowLayoutGrowthDirection(x,y)self.growth={x,y}end
    function methods:SetFlowLayoutMaximumLineSize(value)self.maxLine=value end
    function methods:SetFlowLayoutAxis(value)self.axis=value end
    function methods:SetFlowLayoutPadding(...)self.padding={...}end
    function methods:SetEditModePreviewEnabled(value)self.preview=value end
    function methods:SetAuraProcessingPolicy(policy,options)self.policy,self.policyOptions=policy,options end
    function methods:SetIcon(region)self.iconSink=region end
    function methods:SetDurationCooldown(region)self.cooldownSink=region end
    function methods:SetDurationText(region,options)
        self.durationSink,self.durationOptions=region,options
        self.registeredTextScale=region.textScale
    end
    function methods:SetApplicationCount(region)self.countSink=region end
    function methods:AddDispelTypeTexture(region,options)
        self.dispelSinks=self.dispelSinks or {}
        self.dispelSinks[#self.dispelSinks+1]={region=region,options=options}
    end
    function methods:CreateTexture()return e.CreateFrame("Texture",nil,self)end
    function methods:AddAuraGroup(key,filter,options)
        self.groups=self.groups or {};self.groups[key]={filter=filter,options=options,enabled=true,buttons={}}
        self.buttons=self.buttons or {}
        -- Blizzard's fixed creation batch obfuscates active aura count.
        for i=1,10 do
            local button=e.CreateFrame("AuraButton",nil,self,"FluxRaidAuraIconTemplate")
            button.nativeButton=true
            if options.initializeFrame then
                if e.swallowInitializerErrors then pcall(options.initializeFrame,button)else options.initializeFrame(button)end
            end
            button.nativeRestricted=true
            self.buttons[#self.buttons+1]=button
            self.groups[key].buttons[i]=button
        end
    end
    function methods:AddAuraSlot(key,filter,options)
        self.slots=self.slots or{}
        local button=e.CreateFrame("AuraButton",nil,self,options.templateNames[1])
        button.nativeButton=true
        if options.initializeFrame then options.initializeFrame(button)end
        button.nativeRestricted=true
        self.slots[key]={filter=filter,options=options,button=button}
        return button
    end
    function methods:SetAuraGroupLayout(key,layout)self.groups[key].options.layout=layout end
    function methods:SetAuraGroupMaxFrameCount(key,count)self.groups[key].options.maxFrameCount=count end
    function methods:SetAuraGroupCandidateFilters(key,filters)self.groups[key].options.candidateFilters=filters end
    function methods:SetAuraGroupFilterString(key,filter)self.groups[key].filter=filter end
    function methods:SetAuraGroupEnabled(key,value)self.groups[key].enabled=value end
    e.CreateFrame=function(kind,name,parent,template)
        if template=="FluxRaidDispelBorderTemplate"and e.missingBorderTemplate then error("model missing bare native dispel border template")end
        if kind=="AuraContainer" then
            if failAt and #boxes+1==failAt then error("model missing native capability")end
        end
        assert(not e.combat,"aura widgets are allocated only outside combat")
        local frame=setmetatable({kind=kind,parent=parent,template=template,points={},shown=true},{__index=methods})
        frames[#frames+1]=frame
        -- Native intrinsic Blizzard_AuraContainer.xml initializes both fields.
        if kind=="AuraContainer"then frame.enabled=true;frame.unit="none";boxes[#boxes+1]=frame end
        if template=="FluxRaidAuraIconTemplate"then
            if e.missingNativeDurationSink and kind=="AuraButton"then frame.SetDurationText=false end
            frame.AuraTextLayer=e.CreateFrame("Frame",nil,frame)
            frame.Icon=e.CreateFrame("Texture",nil,frame)
            frame.Count=e.CreateFrame("FontString",nil,frame)
            frame.Duration=e.CreateFrame("FontString",nil,frame)
            frame.Cooldown=e.CreateFrame("Cooldown",nil,frame)
            frame.Cooldown.shown=false -- inherited CooldownFrameTemplate hidden=true
            frame.Cooldown.countdown=e.CreateFrame("FontString",nil,frame.Cooldown)
        end
        return frame
    end
    local frame=e.CreateFrame("Button")
    frame.healthBar=e.CreateFrame("StatusBar",nil,frame)
    frame.healthBar.width=66
    frame._fluxAuraLayer=e.CreateFrame("Frame",nil,frame)
    frame._fluxTextLayer=e.CreateFrame("Frame",nil,frame)
    frame._fluxHighlightLayer=e.CreateFrame("Frame",nil,frame)
    frame._fluxHighlightLayer.level=24
    frame._fluxTrimLayer=e.CreateFrame("Frame",nil,frame)
    frame._fluxTrimLayer.level=20
    frame.unit,frame.optionTable="party1",{}
    local data={}
    e.C_UnitAuras={GetAuraDataByIndex=function(unit,index,filter)
        check(unit==frame.unit,"aura scans follow bound unit")
        return data[filter]and data[filter][index]
    end}
    -- Execute the actual shared geometry implementation. Text metrics remain a
    -- separate fixture contract so these tests do not pretend to measure fonts.
    RunScript("RaidFrame/FluxRaidVisuals.lua",e,"_FluxUI",e.addonNS)
    e.FluxRaidVisuals.ApplyRaidFrameTunables(e.raidDB)
    e.FluxRaidVisuals.GetAuraDurationFontSize=function()return 7 end
    e.FluxRaidVisuals.GetAuraDurationTextScale=function()return 1 end
    if native then
        local cache=os.getenv("FLUX_RAID_UPSTREAM_CACHE")
        local branch=client=="live"and"live"or"forever"
        local path=(cache and cache.."/"..branch.."/"or"../__AddonsForRef/wow-ui-source-"..branch.."/")
            .."Interface/AddOns/Blizzard_SharedXMLBase/AnchorUtil.lua"
        e.CreateFromMixins=function(...)local output={};for i=1,select("#",...)do for key,value in pairs(select(i,...))do output[key]=value end end;return output end
        e.GetValueOrCallFunction=function(object,key)local value=object[key];if type(value)=="function"then return value()end;return value end
        e.GenerateClosure=function(fn,...)local args={...};return function(...)return fn((unpack or table.unpack)(args),...)end end
        e.secretwrap=function(...)return ... end
        RunScript(path,e)
    end
    NativePolicy(e,client or "forever")
    local module=loadModule(e)
    return e,module,frame,frames,boxes,data
end

for _,client in ipairs({"retail","forever"})do
    local e,auras,frame,frames,boxes=Fixture(true,nil,nil,client=="retail"and"live"or"forever")
    check(auras.Setup(frame),client.." native setup succeeds")
    check(frame._fluxAuraNative==true and #boxes==5,"three native icon containers plus independent raid border and party glow owners")
    local groups,rows=frame._fluxAuraContainers,frame._fluxAuraRows
    local geometry=e.FluxRaidVisuals.GetAuraLayout(e.FluxRaidVisuals.FRAME_WIDTH-7,frame.healthBar:GetHeight(),e.raidDB)
    check(rows.top.clips and rows.bottom.clips and rows.top.width==geometry.buffs.blockWidth
        and rows.top.height==geometry.buffs.blockHeight and rows.bottom.height==geometry.debuffs.blockHeight,
        "clipped side blocks use the shared three-column/two-row geometry")
    check(rows.top.parent==frame._fluxAuraLayer and rows.bottom.parent==frame._fluxAuraLayer,
        "aura blocks use their dedicated layer below text")
    check((rows.top.width+rows.bottom.width<=frame._fluxAuraRowMetrics.rowWidth and rows.top.height<=frame.healthBar:GetHeight())
        or frame._fluxAuraRowMetrics.overlap,
        "shared owned health bounds report overlap when the selected aura blocks exceed the frame")
    check(rows.top.alpha==0.3 and rows.bottom.alpha==0.3,"requested seventy percent transparency applies to both aura rows")
    check(rows.top.points[1][1]=="TOPRIGHT" and rows.bottom.points[1][1]=="TOPLEFT"
        and groups.buffs.anchor=="TOPRIGHT" and groups.buffs.growth[1]==e.AnchorUtil.FlowDirection.Left
        and groups.dispel.anchor=="TOPLEFT" and groups.dispel.growth[1]==e.AnchorUtil.FlowDirection.Right,
        "latest user alignment keeps buffs on the right and debuffs on the left with downward row growth")
    check(groups.buffs.groups.classBuffs.filter=="HELPFUL"and groups.buffs.groups.raidBuffs.filter=="HELPFUL","class and native raid buffs share the right block")
    check(groups.buffs.policy==e.CustomAuraContainerAuraProcessingPolicy.ProcessAura
        and groups.buffs.groups.raidBuffs.options.candidateFilters.processedAuraType==e.AuraUtil.AuraUpdateChangedType.Buff
        and not groups.buffs.groups.raidBuffs.options.candidateFilters.maxDuration,"native raid buff classification replaces arbitrary duration and shield exclusions")
    check(groups.dispel.groups.bossBuffs.filter=="HELPFUL"and groups.dispel.groups.debuffs.filter=="HARMFUL","native boss helpful and harmful categories share the left block")
    check(groups.dispel.groups.priorityDebuffs.options.candidateFilters.processedAuraType==e.AuraUtil.AuraUpdateChangedType.Debuff
        and groups.dispel.groups.debuffs.options.candidateFilters.isPriorityAura==false,"native debuff categories are disjoint by gameplay priority")
    local buttons=0
    for key,box in pairs(groups)do
      if key~="dispelBorder"and key~="partyDispelGlow"then
        local slot=11
        check(box.maxLine==2*slot+geometry.base.gap and box.axis==e.AnchorUtil.FlowLayoutAxis.Vertical and box.growth[2]==e.AnchorUtil.FlowDirection.Down,"native flow wraps after three icons and grows down")
        for groupKey,group in pairs(box.groups)do
            check(group.options.maxFrameCount==6 and group.options.layout.elementWidth==slot and group.options.layout.elementHeight==slot,
                "each native category has six rectangular slots")
            for _,button in ipairs(group.buttons)do
                buttons=buttons+1
                local glyph=11
                check(button.width==glyph and button.height==glyph,"native glyphs use square normal and larger boss sizing")
                check(button.iconSink==button.Icon and button.cooldownSink==button.Cooldown
                    and button.durationSink==button.Duration and button.countSink==button.Count,"native initializer registers every display sink")
                check(button.Count.parent==button.AuraTextLayer and button.Duration.parent==button.AuraTextLayer
                    and button.AuraTextLayer.level==button:GetFrameLevel()+3,"one-time native text host draws duration and stacks above child cooldown")
                check(button.Duration.font[2]==10 and button.Duration.font[3]=="" and button.Duration.width==glyph+2
                    and button.Duration.wordWrap==false and button.Duration.points[1][1]=="CENTER"
                    and button.Duration.textColor[4]==1 and button.Duration.shadowColor[4]==1 and button.Duration.textScale==1,
                    "bounded outlined native duration is centered above the icon with a dark shadow")
                check(button.Cooldown.hideCountdown==true and button.Cooldown.drawSwipe==true
                    and button.Cooldown.swipeColor[4]==0.75 and button.Cooldown.reverse==true
                    and button.Cooldown.allpoints==button and button.Cooldown.drawBling==false
                    and button.Cooldown.shown==true and button.Cooldown.swipeTexture[1]=="Interface\\Buttons\\WHITE8X8"
                    and button.Cooldown.swipeTexture[5]==1,
                    "native duration text coexists with a full-icon reverse swipe without duplicate numbers")
            end
        end
      end
    end
    check(buttons==120,"native fixed creation batches are recorded separately from visible twelve-slot capacity")
    check(#groups.dispel.groups.dispel.buttons[1].dispelSinks==1,"clipped icon retains only its local dispel edge")
    local border=groups.dispelBorder
    local slot=border.slots.dispel
    check(border.parent==frame._fluxHighlightLayer and not border.clips and border.allpoints==frame,
        "whole-cell border uses an unclipped native owner on the dedicated highlight layer")
    check(slot.filter=="HARMFUL|RAID" and slot.options.templateNames[1]=="FluxRaidDispelBorderTemplate"
        and slot.options.candidateFilters.processedAuraType==e.AuraUtil.AuraUpdateChangedType.Dispel and border.policyOptions.displayOnlyDispellableDebuffs,
        "one fixed public slot selects actual dispellable raid auras through native classification")
    check(not slot.button.Icon and not slot.button.Duration and not slot.button.Cooldown
        and #slot.button.dispelSinks==4,"bare native slot owns only four type-colored border sinks")
    check(slot.button.level==26 and slot.button.level>frame._fluxTrimLayer.level and slot.button.mouse==false,
        "non-clickable native border draws above bronze trim")
    for _,sink in ipairs(slot.button.dispelSinks)do
        local texture=sink.region
        check(texture.parent==slot.button and sink.options.style==3,"full-frame hint has a native-owned descendant color sink")
        local first,last=texture.points[1],texture.points[2]
        check(first[2]==frame and last[2]==frame,"native border sinks attach to the owned cell geometry")
        check((texture.height==2 or texture.width==2) and first[4]~=0 and last[4]~=0,
            "native type strip stays two pixels inside the horizontal body edges")
        check((first[5]==-2 or first[5]==6) and (last[5]==-2 or last[5]==6),
            "border top is inset and bottom clears the connected four-pixel overlap")
    end
    auras.Update(frame)
    check(groups.buffs.groups.classBuffs.enabled and groups.buffs.groups.raidBuffs.enabled
        and groups.buffs.unit=="party1","native present class buffs remain visible out of combat")
    check(not border.shown and groups.partyDispelGlow.shown and groups.partyDispelGlow.unit=="party1","party uses its independent native glow owner")
    e.restricted=true;e.combat=true;auras.Update(frame)
    check(not groups.buffs.groups.classBuffs.enabled and groups.buffs.groups.raidBuffs.enabled,"combat disables class group without disabling short buffs")
    e.combat=false;e.dispelHighlight=false;auras.Update(frame)
    check(groups.buffs.groups.classBuffs.enabled and not groups.dispel.shown and groups.dispelPlain.shown,"OOC class restore and dispel highlight toggle use public group ownership only")
    check(not border.shown and border.unit=="none"and not border.events,"dispel highlight disable retires the independent slot owner")
    frame.optionTable.displayOnlyDispellableDebuffs=true;auras.Update(frame)
    for _,key in ipairs({"dispel","dispelPlain"})do
        local box=groups[key]
        check(box.groups.dispel.options.maxFrameCount==6 and box.groups.dispel.options.candidateFilters.isBossOrRoleAura==false
            and box.groups.bossDebuffs.filter=="HARMFUL|RAID",
            "strict mode reserves all six raw HARMFUL|RAID slots including dispellable boss auras")
        for _,key in ipairs({"bossBuffs","priorityDebuffs","debuffs"})do check(not box.groups[key].enabled,"strict mode has no helpful boss, priority or ordinary exceptions")end
    end
    frame.optionTable.displayBuffs=false;frame.optionTable.displayDebuffs=false;auras.Update(frame)
    for _,box in pairs(groups)do check(not box.shown and box.unit=="none"and not box.events,"disabled rows release native unit subscriptions")end
    frame.optionTable={};frame.unit="party2";auras.Update(frame)
    check(groups.buffs.unit=="party2"and groups.dispelPlain.unit=="party2","native row owners follow unit reassignment")
    e.dispelHighlight=true;auras.Update(frame)
    check(not border.shown and groups.partyDispelGlow.shown and groups.partyDispelGlow.unit=="party2","native party glow follows the reassigned unit through its public owner")
    local count=#frames
    for i=1,50 do auras.Refresh(frame)end
    check(#frames==count,"repeated native refreshes allocate no pools, frames or containers")
    e.raidDB.auraIconScale=0.5;e.FluxRaidVisuals.FRAME_WIDTH=60;auras.Refresh(frame)
    local fitted=e.FluxRaidVisuals.GetAuraLayout(53,frame.healthBar:GetHeight(),e.raidDB)
    check(#frames==count and groups.buffs.scale<1 and math.abs(groups.buffs.scale-fitted.scale)<1e-8
        and math.abs(rows.top.width-fitted.buffs.blockWidth)<1e-8 and math.abs(rows.top.height-fitted.buffs.blockHeight)<1e-8,
        "public scale adapts both three-by-two blocks without forbidden child mutations")
    check(border.scale==nil and border.maxLine==nil,"icon uniform scaling never changes the whole-cell border geometry")
    e.combat=true;auras.Refresh(frame)
    check(frame._fluxNeedsPrivateAuraSync and #frames==count,"combat sizing changes defer all allocation and layout work")
    auras.Clear(frame)
    for _,box in pairs(groups)do check(not box.shown and box.unit=="none"and not box.events,"clear retires every native owner")end
    check(not rows.top.shown and not rows.bottom.shown,"clear hides both row hosts")
end

local function Aura(id,duration,extra)
    local aura={name="aura"..id,spellId=id,auraInstanceID=id,icon=id+1000,duration=duration,expirationTime=100,applications=1,
        sourceUnit="player",canApplyAura=true,isPriorityAura=false,isRaid=false,isBossAura=false,isHelpful=false,isHarmful=false,
        isTankRoleAura=false,isHealerRoleAura=false,isDPSRoleAura=false,isNameplateOnly=false}
    for k,v in pairs(extra or{})do aura[k]=v end
    return aura
end
local function Shown(list)
    local n=0;for _,icon in ipairs(list)do if icon.shown then n=n+1 end end;return n
end
for _,client in ipairs({"era","anniversary","classic"})do
    local e,auras,frame,frames,boxes,data=Fixture(false,nil,nil,client=="era"and"classic_era"or(client=="anniversary"and"classic_anniversary"or"classic"))
    data.HELPFUL={Aura(1243,1800,{isHelpful=true,expirationTime=2000}),Aura(17,30,{isHelpful=true,applications=3}),
        Aura(10,0,{isHelpful=true}),Aura(11,120,{isHelpful=true}),Aura(100,15,{isHelpful=true}),Aura(101,15,{isHelpful=true}),Aura(102,15,{isHelpful=true})}
    data["HARMFUL|RAID"]={Aura(301,20,{isHarmful=true,isRaid=true,canActivePlayerDispel=true,dispelName="Poison"}),
        Aura(302,20,{isHarmful=true,isRaid=true,canActivePlayerDispel=true,dispelName="Magic"})}
    data.HARMFUL={Aura(200,15,{isHarmful=true}),Aura(301,20,{isHarmful=true,isRaid=true,dispelName="Poison"}),
        Aura(403,20,{isHarmful=true}),Aura(400,30,{isHarmful=true,isBossAura=true}),
        Aura(404,0,{isHarmful=true,isBossAura=true}),Aura(405,500,{isHarmful=true}),Aura(406,0,{isHarmful=true})}
    check(auras.Setup(frame),client.." readable setup succeeds")
    check(not frame._fluxAuraNative and #boxes==0,"readable clients avoid unavailable native intrinsic")
    auras.Update(frame)
    local lists,rows=frame._fluxAuraCorners,frame._fluxAuraRows
    local geometry=e.FluxRaidVisuals.GetAuraLayout(e.FluxRaidVisuals.FRAME_WIDTH-7,frame.healthBar:GetHeight(),e.raidDB)
    check(#lists.buffs==6 and #lists.debuffs==6 and Shown(lists.buffs)==6 and Shown(lists.debuffs)==6,
        "six distinct buffs and six distinct debuffs fit separate three-by-two side blocks")
    check(lists.buffs[1].Icon.texture==1010 and lists.buffs[2].Icon.texture==1011 and lists.buffs[3].Icon.texture==1017,
        "native buff priority retains permanent, long and shield auras without arbitrary exclusions")
    check(lists.buffs[2].Cooldown.hideCountdown==false and lists.buffs[2].Cooldown.countdown.font[2]==10
        and lists.buffs[2].Cooldown.start==-20 and lists.buffs[2].Cooldown.duration==120,"long native buff duration remains visible in small cooldown text")
    check(lists.buffs[3].Count.text==3 and lists.buffs[3].Cooldown.start==70,"shield stacks and duration remain accurate")
    check(lists.buffs[1].Cooldown.drawSwipe and lists.buffs[1].Cooldown.swipeColor[4]==0.75,"readable aura duration retains a clear cooldown swipe")
    local timed=lists.buffs[2]
    check(timed._fluxCountdownText==timed.Cooldown.countdown and timed._fluxCountdownText.parent==timed.AuraTextLayer
        and timed._fluxCountdownText.points[1][1]=="CENTER" and timed._fluxCountdownText.shown
        and timed._fluxCountdownText.width==geometry.buffs.width+2 and timed.Cooldown.level<timed.AuraTextLayer.level,
        "readable duration is centered on its own layer above the full-icon swipe")
    check(not lists.buffs[1]._fluxCountdownText.shown and not lists.buffs[1].Cooldown.shown,
        "permanent buffs have no invented timer or cooldown sweep")
    data.HELPFUL[4].duration=0; auras.Update(frame)
    check(not timed._fluxCountdownText.shown and not timed.Cooldown.shown and timed.Cooldown.duration==0,
        "timed-to-permanent reuse clears the cooldown and detached timer text")
    data.HELPFUL[4].duration=120; auras.Update(frame)
    check(timed._fluxCountdownText.shown and timed.Cooldown.shown and timed.Cooldown.duration==120,
        "a reused timed aura restores the native countdown and sweep")
    local seen={}
    for i,icon in ipairs(lists.buffs)do
        check(icon.width==geometry.buffs.width and icon.height==geometry.buffs.height and icon.parent==rows.top and icon.points[1][1]=="TOPRIGHT"
            and icon.points[1][4]==-math.floor((i-1)/2)*(geometry.buffs.width+geometry.buffs.gap)
            and icon.points[1][5]==-((i-1)%2)*(geometry.buffs.height+geometry.buffs.gap),
            "buff geometry has three columns and two rows growing left/down from the right edge")
        check(not seen[icon.Icon.texture],"top row has no duplicate aura");seen[icon.Icon.texture]=true
    end
    seen={}
    for i,icon in ipairs(lists.debuffs)do
        local glyph=geometry.debuffs.width
        check(icon.width==glyph and icon.height==glyph and icon.parent==rows.bottom
            and icon.points[1][4]==math.floor((i-1)/2)*(geometry.debuffs.slotWidth+geometry.debuffs.gap)
            and icon.points[1][5]==-((i-1)%2)*(geometry.debuffs.slotHeight+geometry.debuffs.gap),
            "all harmful effects use three columns and two rows in the left block")
        check(not seen[icon.Icon.texture],"bottom row has no duplicate aura");seen[icon.Icon.texture]=true
    end
    check(lists.debuffs[1].Icon.texture==1400 and lists.debuffs[2].Icon.texture==1404
        and lists.debuffs[3].Icon.texture==1301 and lists.debuffs[4].Icon.texture==1302,"native debuff ordering puts boss effects before raid dispels and ordinary effects")
    for i=1,6 do data["HARMFUL|RAID"][i]=Aura(300+i,20,{isHarmful=true,isRaid=true,dispelName="Magic"})end
    frame.optionTable.displayOnlyDispellableDebuffs=true;auras.Update(frame)
    check(Shown(lists.debuffs)==6 and lists.debuffs[6].Icon.texture==1306,"strict dispel-only uses all six slots exclusively from the filtered raid list")
    for _,icon in ipairs(lists.debuffs)do check(icon.Icon.texture>=1301 and icon.Icon.texture<=1306,"strict mode excludes every own/boss/nondispellable exception")end
    local count=#frames
    for i=1,20 do auras.Refresh(frame)end
    check(#frames==count,"readable refreshes reuse twelve fixed icon frames")
    frame.optionTable.displayBuffs=false;auras.Update(frame)
    check(Shown(lists.buffs)==0 and not rows.top.shown,"buff master setting clears the entire top row")
    frame.unit=nil;auras.Update(frame)
    check(Shown(lists.debuffs)==0 and not rows.bottom.shown,"unit removal clears the complete bottom row")
    auras.Clear(frame)
    check(not rows.top.shown and not rows.bottom.shown,"readable cleanup hides both bounded hosts")
end

-- Execute the pinned owner membership gate and native flow over independent
-- synthetic elements. We inspect owned viewport geometry only; native buttons
-- stay opaque. This verifies clipping math, not the engine's rendering VM.
do
    local cache=os.getenv("FLUX_RAID_UPSTREAM_CACHE")
    local function nativeSource(name,branch)
        local root=cache and cache.."/"..(branch or "forever").."/"or"../__AddonsForRef/wow-ui-source-"..(branch or "forever").."/"
        local f=assert(io.open(root.."Interface/AddOns/Blizzard_AuraContainer/"..name,"rb"));local text=f:read("*a");f:close();return text:gsub("\r\n","\n")
    end
    local function namedFunction(text,name)
        return assert(text:match("function "..name:gsub("%.","%%.").."%b().-\nend"),name)
    end
    local function nativeProjection(e,frame,key,data)
        local box=frame._fluxAuraContainers[key]
        if not box or not box:IsVisible() then return {} end
        local groups={};for _,group in pairs(box.groups)do if group.enabled then groups[#groups+1]=group end end
        table.sort(groups,function(a,b)return a.options.layout.layoutIndex<b.options.layout.layoutIndex end)
        local descriptions={}
        for _,group in ipairs(groups)do
            local members={}
            local contract={GetFilterString=function()return group.filter end,GetCandidateFilters=function()return group.options.candidateFilters end}
            for _,aura in ipairs(data[group.filter]or{})do
                local copy={};for field,value in pairs(aura)do copy[field]=value end
                local opts=box.policyOptions or{}
                copy.processedAuraType=e.AuraUtil.ProcessAura(copy,opts.displayOnlyDispellableDebuffs,opts.ignoreBuffs,opts.ignoreDebuffs,opts.ignoreDispelDebuffs)
                if e.AuraContainerAuraGroupOwnerMixin.ShouldIncludeAuraInGroup({},contract,frame.unit,copy,true)then members[#members+1]=copy end
            end
            local compare=group.options.sortMethod==e.AuraContainerSortMethod.UnitFrameDebuff and e.AuraUtil.UnitFrameDebuffComparator or e.AuraUtil.DefaultAuraCompare
            table.sort(members,compare)
            local options=group.options.layout
            local description={elements={},elementSpacing=options.elementSpacing,lineSpacing=options.lineSpacing,
                groupSpacing=options.groupSpacing,groupLineSpacing=options.groupLineSpacing,forceNewLine=options.forceNewLine,
                elementWidth=options.elementWidth,elementHeight=options.elementHeight}
            for index=1,math.min(#members,group.options.maxFrameCount)do
                -- The supported layout slot can be larger than the glyph.
                -- These dimensions were captured by our initializer model;
                -- the production code never revisits a registered aura child.
                local prototype=group.buttons[1]
                local element={id=members[index].auraInstanceID,width=prototype.width,height=prototype.height}
                function element:GetSize()return self.width,self.height end
                function element:ClearAllPoints()end
                function element:SetPoint(_,_,_,x,y)self.x,self.y=x,y end
                description.elements[#description.elements+1]=element
            end
            descriptions[#descriptions+1]=description
        end
        local layout=e.AnchorUtil.CreateFlowLayout()
        for name,method in pairs(e.CustomAuraContainerFlowLayoutMixin)do layout[name]=method end
        layout:SetAnchorPoint(box.anchor);layout:SetGrowthDirection((unpack or table.unpack)(box.growth))
        layout:SetLayoutAxis(box.axis);layout:SetMaximumLineSize(box.maxLine);layout:SetPadding(0,0,0,0)
        local output={SetSize=function(self,w,h)self.width,self.height=w,h end}
        layout:Apply(output,descriptions)
        box.modeledNativeWidth,box.modeledNativeHeight=output.width,output.height
        local row=key:find("buffs",1,true)and frame._fluxAuraRows.top or frame._fluxAuraRows.bottom
        local right=key:find("buffs",1,true)~=nil
        local function origin(region)
            if region==row then return 0,0 end
            local point=assert(region.points[1],"owned viewport needs a fixed point")
            local x,y=origin(point[2]);return x+(right and-point[4]or point[4]),y-point[5]
        end
        local bx,by=origin(box)
        local clip=box.parent
        local cx,cy=origin(clip)
        local visible={}
        for _,description in ipairs(descriptions)do for _,element in ipairs(description.elements)do
            local x=bx+(right and-element.x or element.x)*box.scale
            local y=by-element.y*box.scale
            local width,height=element.width*box.scale,element.height*box.scale
            local ix=math.min(x+width,cx+clip.width)-math.max(x,cx)
            local iy=math.min(y+height,cy+clip.height)-math.max(y,cy)
            if ix>1e-7 and iy>1e-7 then
                check(math.abs(ix-width)<1e-7 and math.abs(iy-height)<1e-7,"native flow projects whole icons without clipped slivers")
                visible[#visible+1]={id=element.id,x=x,y=y}
            end
        end end
        return visible
    end
    local function visibleSequence(e,frame,key,data)
        local all=nativeProjection(e,frame,key,data)
        for _,entry in ipairs(nativeProjection(e,frame,key.."Tail",data))do all[#all+1]=entry end
        table.sort(all,function(a,b)if math.abs(a.x-b.x)>1e-7 then return a.x<b.x end;return a.y<b.y end)
        local ids,seen={},{}
        for _,entry in ipairs(all)do check(not seen[entry.id],"split native viewports never duplicate an aura");seen[entry.id]=true;ids[#ids+1]=entry.id end
        return table.concat(ids,",")
    end
    local function prepareProjection(e,branch)
        e.AuraContainerUtil={};e.AuraContainerAuraGroupOwnerMixin={};e.CustomAuraContainerFlowLayoutMixin={}
        e.C_Secrets={GetSpellAuraSecrecy=function()return 0 end};e.Enum.SecrecyLevel={NeverSecret=0}
        e.UnitIsPlayerControlledOrGroupMember=function()return true end;e.UnitCanAssist=function()return true end
        local utility=nativeSource("Blizzard_AuraContainerUtil.lua",branch)
        for _,name in ipairs({"CanApplyIdentityCandidateFilters","DoesAuraPassCandidateFilters"})do
            RunSource(namedFunction(utility,"AuraContainerUtil."..name),"@native-candidate",e)
        end
        RunSource(namedFunction(nativeSource("Blizzard_AuraContainerGroups.lua"),"AuraContainerAuraGroupOwnerMixin:ShouldIncludeAuraInGroup"),"@native-owner-gate",e)
        local flow=nativeSource("Blizzard_CustomAuraContainer.lua",branch)
        for _,name in ipairs({"GetElementSize","ApplyElementLayout","OnLayoutComplete"})do
            RunSource(namedFunction(flow,"CustomAuraContainerFlowLayoutMixin:"..name),"@native-flow-element",e)
        end
    end
    for _,branch in ipairs({"live","forever"})do
        local e,module,frame,frames,boxes,data=Fixture(true,nil,nil,branch)
        prepareProjection(e,branch)
        module.Setup(frame);module.Update(frame);e.restricted=true
        local function populate(mixed)
            data.HELPFUL={Aura(11,20,{isHelpful=true}),Aura(12,20,{isHelpful=true})}
            for id=201,206 do data.HELPFUL[#data.HELPFUL+1]=Aura(1243,1800,{isHelpful=true,auraInstanceID=id})end
            data.HARMFUL={};data["HARMFUL|RAID"]={}
            local counts=mixed and{1,1,1,2,4}or{2,0,0,2,4}
            local nextID=301
            for category,count in ipairs(counts)do for index=1,count do
                local helpful=category==2
                local aura=Aura(nextID,20,{isHelpful=helpful,isHarmful=not helpful,isBossAura=category<=2,
                    isRaid=category==4,dispelName=category==4 and"Magic"or nil,canActivePlayerDispel=category==4})
                if category==3 then e.priority[nextID]=true end
                local list=helpful and data.HELPFUL or data.HARMFUL;list[#list+1]=aura
                if category==4 then data["HARMFUL|RAID"][#data["HARMFUL|RAID"]+1]=aura end
                nextID=nextID+1
            end end
        end
        for pass=1,2 do for count=1,6 do
            populate(pass==1);e.raidDB.maxBuffs=count;e.raidDB.maxDebuffs=7-count
            module.Refresh(frame);module.Update(frame)
            local expectedBuffs={11,12,201,202,203,204}
            local expectedDebuffs={301,302,303,304,305,306}
            local function prefix(list,n)local out={};for i=1,n do out[i]=list[i]end;return table.concat(out,",")end
            check(visibleSequence(e,frame,"buffs",data)==prefix(expectedBuffs,count),"actual native flow enforces the global buff cap across both categories")
            local actualDebuffs=visibleSequence(e,frame,"dispel",data)
            check(actualDebuffs==prefix(expectedDebuffs,7-count),"actual native flow enforces the global debuff cap across mixed priority categories: "..branch.."/"..pass.."/"..count.." got "..actualDebuffs)
            -- Enough genuine RAID-filter members to exercise strict row two,
            -- including every configured four/five-slot partial viewport.
            for id=501,508 do
                local aura=Aura(id,20,{isHarmful=true,isRaid=true,dispelName="Magic",canActivePlayerDispel=true})
                data.HARMFUL[#data.HARMFUL+1]=aura;data["HARMFUL|RAID"][#data["HARMFUL|RAID"]+1]=aura
            end
            frame.optionTable.displayOnlyDispellableDebuffs=true
            for _,decorated in ipairs({true,false})do
                e.dispelHighlight=decorated;module.Update(frame)
                local key=decorated and"dispel"or"dispelPlain"
                local ids={};for _,aura in ipairs(data["HARMFUL|RAID"])do ids[#ids+1]=aura.auraInstanceID end
                check(visibleSequence(e,frame,key,data)==prefix(ids,math.min(#ids,7-count)),"strict mode filters every visible main and partial-tail slot")
                for _,box in ipairs(boxes)do if box.groups and box.groups.bossDebuffs then
                    for _,group in ipairs({"bossBuffs","priorityDebuffs","debuffs"})do check(not box.groups[group].enabled,"strict state reaches each decorated/plain primary/tail native owner")end
                end end
            end
            frame.optionTable.displayOnlyDispellableDebuffs=false;e.dispelHighlight=true
        end end
        local allocated=#frames
        for repeatIndex=1,12 do e.raidDB.maxBuffs=repeatIndex%6+1;e.raidDB.maxDebuffs=7-e.raidDB.maxBuffs;module.Refresh(frame);module.Update(frame)end
        check(#frames==allocated and #boxes==8,"count toggles reuse the lazily created native pools")
        e.raidDB.maxBuffs=6;e.raidDB.maxDebuffs=6;module.Refresh(frame);module.Update(frame)
        for key,box in pairs(frame._fluxAuraContainers)do if key:find("Tail",1,true)then check(not box.shown and box.unit=="none"and not box.events,"six-slot layout retires duplicate-row subscriptions")end end
        data.HELPFUL={};data.HARMFUL={};data["HARMFUL|RAID"]={};e.raidDB.maxBuffs=3;e.raidDB.maxDebuffs=5;module.Refresh(frame);module.Update(frame)
        check(visibleSequence(e,frame,"buffs",data)==""and frame._fluxAuraContainers.buffsTail:IsVisible(),"empty clipped native owner remains logically shown for later dirty work")
        check(frame._fluxAuraContainers.buffsTail.modeledNativeWidth==1 and frame._fluxAuraContainers.buffsTail.modeledNativeHeight==1,"actual native empty flow collapses owner dimensions without hiding its logical state")
        populate(true);module.Update(frame)
        check(visibleSequence(e,frame,"buffs",data)=="11,12,201","empty-to-populated logical native owner still projects the requested prefix")
        -- Model both the earlier compact health area and the taller main cell.
        -- Use the production limit/helper so every advertised slider step has
        -- room to grow, while exact native flow still enforces the global cap.
        for id=501,508 do
            local aura=Aura(id,20,{isHarmful=true,isRaid=true,dispelName="Magic",canActivePlayerDispel=true})
            data.HARMFUL[#data.HARMFUL+1]=aura;data["HARMFUL|RAID"][#data["HARMFUL|RAID"]+1]=aura
        end
        e.FluxRaidVisuals.FRAME_WIDTH=72
        for _,healthHeight in ipairs({35,44})do
            frame.healthBar.height=healthHeight
            for count=1,6 do
                e.raidDB.maxBuffs=count;e.raidDB.maxDebuffs=count
                local maximum=math.min(2.5,e.FluxRaidVisuals.GetAuraScaleLimit(65,healthHeight,e.raidDB))
                local previous=0
                for _,setting in ipairs({0.5,(0.5+maximum)/2,maximum})do
                    e.raidDB.auraIconScale=setting;module.Refresh(frame);module.Update(frame)
                    local geometry=e.FluxRaidVisuals.GetAuraLayout(65,healthHeight,e.raidDB)
                    check(geometry.base.width==11 and geometry.base.height==11,
                        "every native layout keeps the same native square canonical creation shape")
                    check(geometry.scale>previous and math.abs(frame._fluxAuraContainers.buffs.scale-geometry.scale)<1e-8,
                        "the fitted slider range grows ordinary native auras from the half-size minimum through its maximum")
                    previous=geometry.scale
                    if not geometry.overlap then
                        check(frame._fluxAuraRows.top.height<=healthHeight+1e-7
                            and frame._fluxAuraRows.top.width+frame._fluxAuraRows.bottom.width<=65+1e-7,
                            "scaled native blocks fit when the physical space permits their requested size")
                    else
                        check(geometry.scale>geometry.physicalFitScale and geometry.scale==setting,
                            "small cells retain the selected aura size even when the blocks exceed frame space")
                    end
                    check(visibleSequence(e,frame,"buffs",data)==table.concat({11,12,201,202,203,204},",",1,count),
                        "the effective slider range preserves the global buff prefix at every one-to-six count")
                    check(visibleSequence(e,frame,"dispel",data)==table.concat({301,302,303,304,305,501},",",1,count),
                        "the effective slider range preserves the global mixed-debuff prefix at every one-to-six count")
                    frame.optionTable.displayOnlyDispellableDebuffs=true
                    for _,decorated in ipairs({true,false})do
                        e.dispelHighlight=decorated;module.Update(frame)
                        check(visibleSequence(e,frame,decorated and"dispel"or"dispelPlain",data)
                            ==table.concat({304,305,501,502,503,504},",",1,count),
                            "strict filtering covers every scaled primary/tail slot through the effective slider range")
                    end
                    frame.optionTable.displayOnlyDispellableDebuffs=false;e.dispelHighlight=true
                end
            end
        end
        check(#frames==allocated,"size/count changes reuse native pools at both health heights")
        module.Clear(frame)
        for _,box in ipairs(boxes)do check(not box.shown and box.unit=="none"and not box.events,"cleanup retires every primary and lazy native owner")end
    end
    for _,client in ipairs({"live","forever","classic","classic_era","classic_anniversary"})do
        local e,module,frame,frames,boxes,data=Fixture(true,nil,nil,client)
        e.raidDB.useBlizzardDefaultSizes=nil;e.FluxRaidVisuals.ApplyRaidFrameTunables(e.raidDB)
        frame.healthBar.height=34
        -- The public owner/flow contract is shared; classification below uses
        -- each client's actual pinned AuraUtil policy and known client flags.
        prepareProjection(e,client=="live"and"live"or"forever")
        data.HELPFUL={Aura(11,20,{isHelpful=true}),Aura(12,20,{isHelpful=true})}
        for id=201,206 do data.HELPFUL[#data.HELPFUL+1]=Aura(1243,1800,{isHelpful=true,auraInstanceID=id})end
        data.HELPFUL[#data.HELPFUL+1]=Aura(302,20,{isHelpful=true,isBossAura=true})
        data.HARMFUL={Aura(301,20,{isHarmful=true,isBossAura=true}),
            Aura(303,20,{isHarmful=true,isBossAura=true,isRaid=true,dispelName="Magic",canActivePlayerDispel=true}),
            Aura(304,20,{isHarmful=true,isTankRoleAura=true,isRaid=true,dispelName="Magic",canActivePlayerDispel=true}),
            Aura(305,20,{isHarmful=true})}
        e.priority[305]=true;data["HARMFUL|RAID"]={data.HARMFUL[2],data.HARMFUL[3]}
        for id=306,312 do
            local aura=Aura(id,20,{isHarmful=true,isRaid=true,dispelName="Magic",canActivePlayerDispel=true})
            data.HARMFUL[#data.HARMFUL+1]=aura;data["HARMFUL|RAID"][#data["HARMFUL|RAID"]+1]=aura
        end
        module.Setup(frame);module.Update(frame)
        local initial=frame._fluxAuraContainers
        check(initial.buffs.scale==1,
            client..": absent sizing setting selects default native glyphs without fitting distortion")
        local normal=initial.buffs.groups.raidBuffs.buttons[1]
        local boss=initial.dispel.groups.bossDebuffs.buttons[1]
        local helpfulBoss=initial.dispel.groups.bossBuffs.buttons[1]
        local classic=e.addonNS.Flux.Client.isAnyClassic
        check(normal.width==11 and normal.height==11 and boss.width==11 and boss.height==11
            and helpfulBoss.width==11,client..": normal/boss/role and helpful-boss glyph sizes follow native client policy")
        check(initial.dispel.groups.priorityDebuffs.buttons[1].width==11
            and initial.dispel.groups.dispel.buttons[1].width==11,
            client..": priority and ordinary dispellable glyphs do not inherit boss enlargement")
        check(normal.Count.fontObject=="NumberFontNormal"and normal.Count.points[1][1]=="BOTTOMRIGHT"
            and normal.Count.points[1][2]==normal.Icon and normal.Count.points[1][4]==-2 and normal.Count.points[1][5]==2,
            client..": native stack font and icon-relative anchor are set before sink registration")
        check(normal.Duration.font[2]==10 and normal.durationSink==normal.Duration and normal.Cooldown.drawSwipe,
            client..": native duration font base keeps the explicitly requested visible timer/swipe sinks")
        e.restricted=true
        for count=1,6 do
            e.raidDB.maxBuffs=count;e.raidDB.maxDebuffs=count;frame.optionTable.displayOnlyDispellableDebuffs=false
            module.Refresh(frame);module.Update(frame)
            check(visibleSequence(e,frame,"buffs",data)==table.concat({11,12,201,202,203,204},",",1,count),
                client..": native square buffs retain the exact global mixed-category limit")
            check(visibleSequence(e,frame,"dispel",data)==table.concat({301,303,304,302,305,306},",",1,count),
                client..": actual native flow fits mixed11/16.5 glyphs into uniform slots at every limit")
            frame.optionTable.displayOnlyDispellableDebuffs=true
            for _,decorated in ipairs({true,false})do
                e.dispelHighlight=decorated;module.Update(frame)
                local key=decorated and"dispel"or"dispelPlain"
                check(visibleSequence(e,frame,key,data)==table.concat({303,304,306,307,308,309},",",1,count),
                    client..": strict native boss/ordinary main and tail slots are all authoritative RAID-filter members")
                for _,name in ipairs({key,key.."Tail"})do local box=frame._fluxAuraContainers[name];if box then
                    check(box.groups.bossDebuffs.filter=="HARMFUL|RAID"and box.groups.dispel.filter=="HARMFUL|RAID"
                        and not box.groups.bossBuffs.enabled and not box.groups.priorityDebuffs.enabled,
                        client..": strict two-category owners cannot admit helpful bosses or nondispellable priority auras")
                end end
            end
            e.dispelHighlight=true
        end
        local nativeAllocated=#frames
        frame.optionTable.displayOnlyDispellableDebuffs=false;e.raidDB.auraIconScale=0.5
        e.combat=true;module.Refresh(frame);module.Update(frame)
        check(initial.buffs.scale==1 and #frames==nativeAllocated and frame._fluxNeedsPrivateAuraSync,
            client..": a combat slider change defers protected layout and retains the current size")
        e.combat=false;e.FluxRaidVisuals.ApplyRaidFrameTunables(e.raidDB);module.Refresh(frame)
        check(frame._fluxAuraContainers==initial and initial.buffs.scale==0.5 and #frames==nativeAllocated,
            client..": the half-size slider scales the same native owners without rebuilding glyphs")
        for iteration=1,6 do
            e.raidDB.auraIconScale=iteration%2==0 and 1 or 0.5
            e.FluxRaidVisuals.ApplyRaidFrameTunables(e.raidDB);module.Refresh(frame);module.Update(frame)
        end
        check(#frames==nativeAllocated and not frame._fluxAuraFamilies,
            client..": slider changes reuse one immutable family and never add a second sizing mode")
        e.raidDB.useBlizzardDefaultSizes=false;e.FluxRaidVisuals.ApplyRaidFrameTunables(e.raidDB);module.Refresh(frame)
        check(frame._fluxAuraContainers==initial and initial.buffs.unit==frame.unit and initial.buffs.shown,
            client..": a deprecated mode flag cannot restore the discarded custom sizing mapping")
        module.Clear(frame)
        for _,box in ipairs(boxes)do check(box.unit=="none"and not box.shown and not box.events,
            client..": hide/disable retires every native owner and tail")end
    end
end

do
    for _,client in ipairs({"classic","classic_era","classic_anniversary"})do
        local e,module,frame,frames,_,data=Fixture(false,nil,nil,client)
        data.HELPFUL={};data.HARMFUL={};data["HARMFUL|RAID"]={}
        for id=1,9 do
            data.HELPFUL[id]=Aura(10+id,20,{isHelpful=true})
            data.HARMFUL[id]=Aura(100+id,20,{isHarmful=true})
            data["HARMFUL|RAID"][id]=Aura(200+id,20,{isHarmful=true,isRaid=true,dispelName="Magic",canActivePlayerDispel=true})
        end
        module.Setup(frame);local allocated=#frames
        for count=1,6 do
            e.raidDB.maxBuffs=count;e.raidDB.maxDebuffs=7-count;module.Refresh(frame);module.Update(frame)
            check(Shown(frame._fluxAuraCorners.buffs)==count and Shown(frame._fluxAuraCorners.debuffs)==7-count,
                "readable clients apply independent global buff/debuff limits from one through six")
            frame.optionTable.displayOnlyDispellableDebuffs=true;module.Update(frame)
            for index,icon in ipairs(frame._fluxAuraCorners.debuffs)do if icon.shown then
                check(index<=7-count and icon.Icon.texture>=1201 and icon.Icon.texture<=1209,
                    "every readable strict slot comes from the actual dispellable filter")
            end end
            frame.optionTable.displayOnlyDispellableDebuffs=false
        end
        check(#frames==allocated,"readable count changes never allocate additional icon frames")
    end
    for _,client in ipairs({"live","forever"})do
        local e,module,frame,frames,boxes=Fixture(true,nil,nil,client)
        e.FluxRaidVisuals.FRAME_WIDTH=160;frame.healthBar.height=100
        e.raidDB.auraIconScale=1;module.Setup(frame);module.Update(frame);e.restricted=true
        local first=frame._fluxAuraContainers.buffs.scale
        local allocated=#frames
        e.raidDB.auraIconScale=2.5;module.Refresh(frame);module.Update(frame)
        check(frame._fluxAuraContainers.buffs.scale>first,"normal aura size slider changes native icon scale when fitting space exists")
        e.raidDB.auraIconScale=1;module.Refresh(frame);module.Update(frame)
        check(math.abs(frame._fluxAuraContainers.buffs.scale-first)<1e-8 and #frames==allocated,
            "size slider one-to-large-to-one returns to the same result without native pool rebuilds")
        e.raidDB.auraIconScale=0.5;module.Refresh(frame);module.Update(frame)
        check(frame._fluxAuraContainers.buffs.scale<first,"new half-size minimum shrinks ordinary native auras below the one-size setting")
        e.raidDB.auraIconScale=1;module.Refresh(frame);module.Update(frame)
        local fresh,freshModule,freshFrame=Fixture(true,nil,nil,client)
        fresh.FluxRaidVisuals.FRAME_WIDTH=160;freshFrame.healthBar.height=100;fresh.raidDB.auraIconScale=2.5
        freshModule.Setup(freshFrame);fresh.raidDB.auraIconScale=1;freshModule.Refresh(freshFrame)
        check(math.abs(freshFrame._fluxAuraContainers.buffs.scale-first)<1e-8,
            "native reload history cannot bake the old aura scale into later settings")
        for _,button in ipairs(freshFrame._fluxNativeAuraButtons)do check(button.width==button.height and(button.width==11 or button.width==16.5),"native creation remains canonical at every saved aura size")end
        check(freshFrame._fluxAuraContainers.buffs.groups.raidBuffs.options.layout.elementWidth==11
            and freshFrame._fluxAuraContainers.dispel.groups.bossDebuffs.options.layout.elementWidth==11,
            "saved slider values never change canonical native flow slot dimensions")

        local before=#frames
        e.combat=true;e.raidDB.maxBuffs=3;e.raidDB.maxDebuffs=5;module.Refresh(frame);module.Update(frame)
        check(#frames==before and #boxes==5 and frame._fluxNeedsPrivateAuraSync,
            "first partial-row request in combat defers new viewports and native pools")
        e.combat=false;module.Refresh(frame);module.Update(frame)
        check(#boxes==8 and frame._fluxAuraContainers.buffsTail.unit==frame.unit and frame._fluxAuraContainers.dispelTail.unit==frame.unit,
            "deferred partial rows initialize and bind after combat using existing public owners")
        local complete=#frames
        for repeatIndex=1,8 do e.raidDB.maxBuffs=repeatIndex%2==0 and 4 or 5;e.raidDB.maxDebuffs=9-e.raidDB.maxBuffs;module.Refresh(frame);module.Update(frame)end
        check(#frames==complete,"repeated four/five switches reuse their native tail pools")
    end
end

do
    for _,client in ipairs({"classic","classic_era","classic_anniversary"})do
        local e,module,frame,frames,_,data=Fixture(false,nil,nil,client)
        e.raidDB.useBlizzardDefaultSizes=nil;e.FluxRaidVisuals.ApplyRaidFrameTunables(e.raidDB)
        frame.healthBar.height=34
        local boss=Aura(300,20,{isHarmful=true,isBossAura=true,isRaid=true,dispelName="Magic",canActivePlayerDispel=true})
        local role=Aura(302,20,{isHarmful=true,isHealerRoleAura=true,isRaid=true,dispelName="Magic",canActivePlayerDispel=true})
        data.HARMFUL={boss,Aura(301,20,{isHarmful=true}),role,Aura(303,20,{isHarmful=true})}
        e.priority[303]=true
        data.HELPFUL={Aura(10,20,{isHelpful=true}),Aura(400,20,{isHelpful=true,isBossAura=true})}
        data["HARMFUL|RAID"]={boss,role}
        for id=500,507 do
            local aura=Aura(id,20,{isHarmful=true,isRaid=true,dispelName="Magic",canActivePlayerDispel=true})
            data.HARMFUL[#data.HARMFUL+1]=aura;data["HARMFUL|RAID"][#data["HARMFUL|RAID"]+1]=aura
        end
        module.Setup(frame);module.Update(frame)
        local buffs,debuffs=frame._fluxAuraCorners.buffs,frame._fluxAuraCorners.debuffs
        check(buffs[1].width==11 and buffs[1].height==11 and debuffs[1].width==11
            and debuffs[2].width==11 and debuffs[3].width==11 and debuffs[4].width==11,
            client..": readable native glyphs distinguish boss, role, helpful boss and ordinary priority effects")
        check(debuffs[2].points[1][4]==0 and debuffs[4].points[1][5]==-11
            and debuffs[1].Count.fontObject=="NumberFontNormal",
            client..": readable native glyphs occupy the same reserved slots and stack-font contract")
        frame.optionTable.displayOnlyDispellableDebuffs=true;module.Update(frame)
        for _,icon in ipairs(debuffs)do if icon.shown then
            local id=icon.Icon.texture-1000
            check(id==300 or id==302 or id>=500 and id<=507,
                client..": every readable native strict glyph comes from the actual RAID-filter list")
            check(icon.width==11,
                client..": readable strict mode retains native boss/role size without enlarging ordinary dispels")
        end end
        local allocated=#frames
        for iteration=1,6 do
            e.raidDB.auraIconScale=iteration%2==0 and 1 or 0.5
            e.FluxRaidVisuals.ApplyRaidFrameTunables(e.raidDB);module.Refresh(frame)
        end
        check(#frames==allocated and frame._fluxAuraCorners.debuffs==debuffs and debuffs[1].width==11,
            client..": readable slider changes reuse their existing glyph pool in place")
    end
end

do
    local e,auras,frame,frames,boxes=Fixture(true,2)
    auras.Setup(frame)
    check(not frame._fluxAuraNative and frame._fluxAuraCorners~=nil,"partial native initialization falls back explicitly")
    check(frame._fluxAuraNativeError and #boxes==1 and not boxes[1].shown and boxes[1].unit=="none","partial native container remains excluded and retired")
    local count=#frames;for i=1,20 do auras.Setup(frame)end
    check(#frames==count,"failed native capability never repeatedly allocates")
end
do
    local e,auras,frame,frames,boxes=Fixture(true)
    e.missingBorderTemplate=true
    auras.Setup(frame)
    check(not frame._fluxAuraNative and frame._fluxAuraNativeError
        and frame._fluxAuraNativeError:find("bare native dispel border",1,true),
        "missing native slot template retains the exact setup failure reason")
    check(#boxes==4 and frame._fluxAuraCorners~=nil,"slot initialization failure retires all excluded owners and uses readable fallback")
    for _,box in ipairs(boxes)do check(not box.shown and box.unit=="none"and not box.events,"slot setup failure retires every partial native subscription")end
    local count=#frames;auras.Setup(frame);check(#frames==count,"failed native slot setup never reallocates its partial trees")
end

do
    local e,auras,frame=Fixture(true)
    e.swallowInitializerErrors=true;e.missingNativeDurationSink=true
    auras.Setup(frame)
    check(not frame._fluxAuraNative and frame._fluxAuraCorners~=nil,"native securecall cannot silently certify incomplete icon initialization")
    check(frame._fluxAuraNativeError and frame._fluxAuraNativeError:find("native aura duration text sink unavailable",1,true),
        "swallowed native initializer failures retain their exact actionable cause")
end
do
    local e,auras,frame=Fixture(true)
    e.FluxRaid_ForEachHeaderChild=function(fn)fn(frame)end
    auras.Setup(frame);auras.Update(frame);e.restricted=true
    local message=auras.Diagnostics()
    check(message:find("aura-policy-20261106c",1,true) and message:find("classIDs=1",1,true) and message:find("hiddenClass=0",1,true),
        "diagnostic reports its bounded stage and factual class/hidden filter counts")
    check(message:find("native=true",1,true) and message:find("bound=party1",1,true) and message:find("row=true",1,true),
        "bounded diagnostic reads own state and owned row only while native children are forbidden")
    frame._fluxAuraNativeError="model initializer error"
    check(auras.Diagnostics():find("model initializer error",1,true),"diagnostic includes the captured setup cause")
end
do
    local e,auras,frame,frames=Fixture(true)
    e.combat=true;local count=#frames;auras.Setup(frame)
    check(#frames==count and frame._fluxNeedsPrivateAuraSync,"combat setup defers all row and pool allocation")
end
do
    local file=assert(io.open("RaidFrame/FluxRaidAuras.lua","rb"));local source=file:read("*a");file:close()
    do
        local e,module,frame=Fixture(true)
        local created,formatter=0,{}
        e.Enum.NumericRuleFormatRounding={Up=0,Down=1}
        e.C_StringUtil={CreateNumericRuleFormatter=function()created=created+1;return formatter end}
        function formatter:SetBreakpoints(rules)self.rules=rules end
        e.FluxRaidVisuals.GetAuraDurationFont=function(nativeDefaults)
            check(nativeDefaults==true,"native initialization selects the native duration font metadata before registration")
            return "Fonts\\FRIZQT__.TTF",10,""
        end
        e.FluxRaidVisuals.GetAuraDurationTextScale=function(width,height)
            check(width==height and(width==11 or width==16.5),"native text scaling uses the actual clipped icon bounds before registration")
            return 0.57
        end
        module.Setup(frame)
        local button=frame._fluxAuraContainers.buffs.groups.raidBuffs.buttons[1]
        check(button.durationOptions.textFormatter==formatter and button.Duration.font[2]==10
            and button.Duration.textScale==0.57 and button.registeredTextScale==0.57,
            "native numeric-only seconds use measured text scale before native binding")
        local rules=formatter.rules
        check(#rules==4 and rules[1].threshold==0 and rules[1].format=="%d" and rules[1].rounding==0
            and rules[2].threshold==60 and rules[2].format=="%dm" and rules[2].components[1].div==60
            and rules[3].threshold==3600 and rules[3].format=="%dh" and rules[3].components[1].div==3600
            and rules[4].threshold==86400 and rules[4].format=="%dd" and rules[4].components[1].div==86400,
            "owned numeric formatter uses explicit seconds/minute/hour/day bands")
        module.Setup(e.CreateFrame("Button"))
        check(created==1,"numeric rule formatter is shared across native icon pools and frames")
    end
    do
        local e,module,frame,_,_,data=Fixture(false,nil,nil,"classic")
        e.FluxRaidVisuals.GetAuraDurationTextScale=function(width,height)return (width/12)*(height/15)*0.57 end
        data.HELPFUL={Aura(10,20,{isHelpful=true})}
        module.Setup(frame);module.Update(frame)
        local icon=frame._fluxAuraCorners.buffs[1]
        local label=icon._fluxCountdownText
        local firstTextScale=(icon.width/12)*(icon.height/15)*0.57
        check(math.abs(label.textScale-firstTextScale)<1e-8 and label.width==icon.width+2,
            "readable countdown text is scaled again after final icon sizing")
        e.FluxRaidVisuals.FRAME_WIDTH=144;e.raidDB.auraIconScale=2.8;frame.healthBar.height=70
        module.Refresh(frame)
        check(label.textScale>firstTextScale,"readable duration grows with larger aura icon bounds")
    end
    do
        local e,module,frame=Fixture(true)
        local created,formatter=0,{}
        e.Enum.SecondsFormatterAbbreviation={OneLetter=2}
        e.Enum.SecondsFormatterIntervalWhitespace={StripIgnoreLocale=2}
        e.Enum.SecondsFormatterInterval={Seconds=0,Days=3}
        e.Enum.SecondsFormatterRounding={Truncate=1}
        e.C_StringUtil={CreateSecondsFormatter=function()created=created+1;return formatter end}
        function formatter:SetDefaultAbbreviation(value)self.abbreviation=value end
        function formatter:SetDesiredUnitCount(value)self.units=value end
        function formatter:SetStripIntervalWhitespace(value)self.whitespace=value end
        function formatter:SetMinInterval(value)self.minimum=value end
        function formatter:SetMaxInterval(value)self.maximum=value end
        function formatter:SetRounding(value)self.rounding=value end
        function formatter:SetCanRoundUpLastUnit(value)self.roundUp=value end
        module.Setup(frame)
        local button=frame._fluxAuraContainers.buffs.groups.raidBuffs.buttons[1]
        check(button.durationOptions.textFormatter==formatter and formatter.abbreviation==2 and formatter.units==1
            and formatter.whitespace==2 and formatter.minimum==0 and formatter.maximum==3
            and formatter.rounding==1 and formatter.roundUp==true,
            "native duration binds an owned compact single-unit formatter without reading remaining time")
        module.Setup(e.CreateFrame("Button"))
        check(created==1,"all native icon pools and unit frames reuse one owned duration formatter")
        local _,fallback,fallbackFrame=Fixture(true)
        fallback.Setup(fallbackFrame)
        check(fallbackFrame._fluxAuraContainers.buffs.groups.raidBuffs.buttons[1].durationOptions==nil,
            "clients without the formatter API retain native duration formatting")
    end
    do
        local changed,count=source:gsub('if icon._fluxCountdownText then icon._fluxCountdownText:Hide%(%) end','-- omitted timer cleanup')
        check(count>0,"negative control targets detached timer cleanup")
        local ok=pcall(function()
            local _,module,frame,_,_,data=Fixture(false,nil,changed,"classic")
            data.HELPFUL={Aura(10,20,{isHelpful=true})};module.Setup(frame);module.Update(frame)
            local icon=frame._fluxAuraCorners.buffs[1]
            assert(icon._fluxCountdownText.shown,"timed aura countdown is active")
            data.HELPFUL[1].duration=0;module.Update(frame)
            assert(not icon._fluxCountdownText.shown,"permanent aura retained detached countdown text")
        end)
        check(not ok,"negative control rejects timer text leaking onto a permanent aura")
    end
    local mutants={
        {"native duration",'button:SetDurationText%(button.Duration,formatter and {textFormatter=formatter} or nil%)',"",function(frame)
            local button=frame._fluxAuraContainers.buffs.groups.classBuffs.buttons[1]
            assert(button.durationSink==button.Duration,"missing native duration display")
        end},
        {"strict all-slot filter",'SetGroup%(frame,key,group,enabled and not strict%)','SetGroup(frame,key,group,enabled)',function(frame)
            assert(not frame._fluxAuraContainers.dispel.groups.priorityDebuffs.enabled,"priority debuffs bypass strict filter")
        end},
        {"native square geometry",'button:SetSize%(metrics.width,metrics.height%)','button:SetSize(metrics.width*2,metrics.height)',function(frame)
            assert(frame._fluxAuraContainers.buffs.groups.raidBuffs.buttons[1].width==11,"normal icons lost native square sizing")
        end},
        {"cooldown swipe",'cooldown:SetDrawSwipe%(true%)','cooldown:SetDrawSwipe(false)',function(frame)
            assert(frame._fluxAuraContainers.buffs.groups.raidBuffs.buttons[1].Cooldown.drawSwipe,"missing cooldown overlay")
        end},
        {"native cooldown visibility",'if native then cooldown:Show%(%) end','-- missing initial cooldown visibility',function(frame)
            assert(frame._fluxAuraContainers.buffs.groups.raidBuffs.buttons[1].Cooldown.shown,"native cooldown inherited hidden template state")
        end},
        {"three-column wrapping",'side.rows%*side.baseSlotHeight%+%(side.rows%-1%)%*base.gap','6*side.baseSlotHeight+5*base.gap',function(frame)
            assert(frame._fluxAuraContainers.buffs.maxLine==22,"six-icon line violates the three-column block")
        end},
    }
    for _,mutant in ipairs(mutants)do
        local changed,count=source:gsub(mutant[2],mutant[3]);check(count>0,"negative control targets "..mutant[1])
        local ok=pcall(function()
            local _,module,frame=Fixture(true,nil,changed)
            module.Setup(frame);frame.optionTable.displayOnlyDispellableDebuffs=true;module.Update(frame);mutant[4](frame)
        end)
        check(not ok,"negative control rejects broken "..mutant[1])
    end
    local nativeMutants={
        {"packed native boss size",'local size=large and geometry.largeRoleEnabled and','local size=true and',function(_,_,frame)
            assert(frame._fluxAuraContainers.dispel.groups.bossDebuffs.buttons[1].width==11,"packed bosses must not reserve larger slots")
        end},
        {"strict native boss query",'strict and "HARMFUL|RAID" or "HARMFUL"','"HARMFUL"',function(_,module,frame)
            frame.optionTable.displayOnlyDispellableDebuffs=true;module.Update(frame)
            assert(frame._fluxAuraContainers.dispel.groups.bossDebuffs.filter=="HARMFUL|RAID","an unfiltered boss bypassed strict native mode")
        end},
        {"retired native unit",'box:SetUnit%("none"%)%;box:Hide%(%)','box:Hide()',function(e,module,frame)
            local original=frame._fluxAuraContainers.buffs
            module.Clear(frame)
            assert(original.unit=="none","a hidden native owner retained its unit subscription")
        end},
        {"native relative slider",'box:SetScale%(geometry.scale%)','box:SetScale(1)',function(e,module,frame)
            e.raidDB.auraIconScale=0.5;module.Refresh(frame)
            assert(frame._fluxAuraContainers.buffs.scale==0.5,"ordinary native icons ignored the relative size slider")
        end},
    }
    for _,mutant in ipairs(nativeMutants)do
        local changed,count=source:gsub(mutant[2],mutant[3]);check(count>0,"native negative control targets "..mutant[1])
        local ok=pcall(function()
            local e,module,frame,frames=Fixture(true,nil,changed,"forever")
            e.raidDB.useBlizzardDefaultSizes=nil;e.FluxRaidVisuals.ApplyRaidFrameTunables(e.raidDB)
            module.Setup(frame);module.Update(frame);e.restricted=true
            mutant[4](e,module,frame,frames)
        end)
        check(not ok,"negative control rejects broken "..mutant[1])
    end
end
print("Raid healer auras: "..checks.." checks; actual native owner/flow projection, global one-to-six limits, native-relative sizing, strict filters and cooldown sinks; eleven rejected negative controls; client visuals/scheduling pending")
