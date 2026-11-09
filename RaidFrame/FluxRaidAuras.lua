local addonName, ns = ...

-- Two bounded 3-by-2 side blocks on owned unit buttons. Native owners classify restricted
-- auras and paint registered sinks; styling changes require explicit native access.
FluxRaidAuras = {}
local A, Compat = FluxRaidAuras, FluxRaidCompat
local floor, min, max = math.floor, math.min, math.max
local SLOTS = 6
local BUFF_BOXES={"buffs","buffsTail"}
local DEBUFF_BOXES={"dispel","dispelPlain","dispelTail","dispelPlainTail"}
local DEBUFF_GROUPS={"bossDebuffs","bossBuffs","priorityDebuffs","dispel","debuffs"}
local ICON_BOXES={"buffs","buffsTail","dispel","dispelPlain","dispelTail","dispelPlainTail"}
local TYPE_COLORS = {Magic={.2,.6,1},Curse={.6,.2,1},Disease={.6,.4,0},Poison={0,.65,0},Bleed={.8,.2,.15}}
local function Secret(value)
    if issecretvalue then return issecretvalue(value) end
    return Compat.IsSecret(value)
end
local function Readable(value)
    return not Secret(value) and not (type(value)=="table" and canaccesstable and not canaccesstable(value))
end
local function Locked() return InCombatLockdown and InCombatLockdown() end
local function Unit(frame) return frame.displayedUnit or frame.unit end
local function RetireOwners(frame)
    for _,box in pairs(frame._fluxAuraContainers or {}) do box:SetUnit("none");box:Hide() end
    if frame._fluxAuraNativeState then frame._fluxAuraNativeState.units={} end
end
local function ClassBuffFilter()
    if FluxRaidHealerExtras and FluxRaidHealerExtras.GetClassBuffFilter then return FluxRaidHealerExtras.GetClassBuffFilter() end
    return {},{}
end
local function ShowClassBuffs()
    if Locked() then return false end
    local db=FluxOptions and FluxOptions.GetRaidFrameDB and FluxOptions:GetRaidFrameDB()
    return not db or db.showClassBuffs~=false
end
local hiddenBuffs,hiddenRevision=nil,0
local function HiddenBuffs()
    if hiddenBuffs then return hiddenBuffs end
    hiddenBuffs={}
    if C_UnitAuras and C_UnitAuras.GetHiddenGroupBuffs then
        local ids=C_UnitAuras.GetHiddenGroupBuffs()
        if Readable(ids) and type(ids)=="table" then
            for _,id in ipairs(ids) do if Readable(id) and type(id)=="number" then hiddenBuffs[id]=true end end
        end
    end
    return hiddenBuffs
end
function A.OnHiddenGroupBuffsChanged()
    hiddenBuffs=nil; hiddenRevision=hiddenRevision+1
end
local function BuffExclusions(classBuffs)
    local excluded={}
    for id in pairs(HiddenBuffs()) do excluded[id]=true end
    if classBuffs then for id in pairs(ClassBuffFilter()) do excluded[id]=true end end
    return excluded
end
local SyncNativeDimensions
local function Dimensions(frame)
    local visual=FluxRaidVisuals
    local db=FluxOptions and FluxOptions.GetRaidFrameDB and FluxOptions:GetRaidFrameDB() or {}
    if frame._fluxAuraNativeMetrics then
        SyncNativeDimensions(frame,db)
        local pending=db; db={}
        for key,value in pairs(pending) do db[key]=value end
        db.auraWidthScale=frame._fluxAuraNativeMetrics.widthScale or 1
    end
    local geometry=visual.GetFrameAuraLayout(frame,db)
    geometry.rowWidth=geometry.availableWidth
    -- Retain the shared metrics for consumers that only need an icon's size.
    geometry.width,geometry.height,geometry.gap=geometry.buffs.width,geometry.buffs.height,geometry.buffs.gap
    return geometry
end
local function EnsureRows(frame)
    if frame._fluxAuraRows then return frame._fluxAuraRows end
    local parent=frame._fluxAuraLayer or frame._fluxTextLayer or frame._fluxContent or frame
    local rows={}
    for _,key in ipairs({"top","bottom"}) do
        local row=CreateFrame("Frame",nil,parent)
        row:EnableMouse(false); row:SetClipsChildren(true); rows[key]=row
        local primary=CreateFrame("Frame",nil,row)
        primary:EnableMouse(false); primary:SetClipsChildren(true); row.primary=primary
    end
    frame._fluxAuraRows=rows
    return rows
end
local EnsureNativeTails
local function ConfigureRows(frame)
    local geometry=Dimensions(frame)
    local base=frame._fluxAuraNativeMetrics
    frame._fluxAuraRowMetrics=geometry
    if base then EnsureNativeTails(frame,geometry) end
    for key,row in pairs(EnsureRows(frame)) do
        local side=key=="top" and geometry.buffs or geometry.debuffs
        row:ClearAllPoints()
        local parent,anchor=FluxRaidVisuals.GetFrameAuraAnchor(frame,key=="top")
        row:SetPoint(anchor,parent,anchor,0,0)
        row:SetSize(side.blockWidth,side.blockHeight)
        row:SetAlpha(FluxRaidVisuals.AURA_ICON_ALPHA or 1)
        local partial=side.count==3 or side.count==5
        row.primary:ClearAllPoints(); row.primary:SetPoint(anchor,row,anchor,0,0)
        local slotWidth,slotHeight=side.slotWidth or side.width,side.slotHeight or side.height
        row.primary:SetSize(partial and (side.columns-1)*slotWidth or side.blockWidth,side.blockHeight)
        if row.tail then
            row.tail:ClearAllPoints(); row.tail:SetPoint(anchor,row,anchor,(anchor=="TOPRIGHT" and -1 or 1)*(side.columns-1)*slotWidth,0)
            row.tail:SetSize(slotWidth,slotHeight)
            row.tail:SetShown(partial)
        end
    end
    if base then
        for _,key in ipairs(ICON_BOXES) do
            local box=frame._fluxAuraContainers[key]
            if box then
                local side=key:find("buffs",1,true) and geometry.buffs or geometry.debuffs
                local helpful=key:find("buffs",1,true)~=nil
                local _,anchor=FluxRaidVisuals.GetFrameAuraAnchor(frame,helpful)
                local row=helpful and frame._fluxAuraRows.top or frame._fluxAuraRows.bottom
                box:ClearAllPoints(); box:SetPoint(anchor,key:find("Tail",1,true) and row or row.primary,anchor,0,0)
                box:SetFlowLayoutAnchorPoint(anchor)
                box:SetFlowLayoutGrowthDirection(anchor=="TOPRIGHT" and AnchorUtil.FlowDirection.Left or AnchorUtil.FlowDirection.Right,AnchorUtil.FlowDirection.Down)
                box:SetScale(geometry.scale)
                local slotWidth=side.baseSlotWidth or (side.slotWidth or side.width)/geometry.scale
                box:SetFlowLayoutMaximumLineSize(side.rows*side.baseSlotHeight+(side.rows-1)*base.gap)
                local groups=key:find("buffs",1,true) and {"raidBuffs","classBuffs"} or DEBUFF_GROUPS
                for index,group in ipairs(groups) do
                    box:SetAuraGroupMaxFrameCount(group,side.count)
                    box:SetAuraGroupLayout(group,{layoutIndex=index,elementSpacing=base.gap,lineSpacing=base.gap,
                        groupSpacing=0,groupLineSpacing=base.gap,forceNewLine=false,elementWidth=slotWidth,elementHeight=side.baseSlotHeight})
                end
            end
        end
    end
end
local function StyleDurationText(text,button,width,fontScale,height)
    FluxRaidVisuals.StyleAuraDuration(text,width,height or button:GetHeight(),button._fluxAuraRenderScale or 1,fontScale)
    text:ClearAllPoints(); text:SetPoint("CENTER",button,"CENTER",0,0)
end
SyncNativeDimensions=function(frame,db)
    local metrics=frame._fluxAuraNativeMetrics
    if not metrics then return end
    local desired=FluxRaidVisuals.GetAuraLayout(nil,nil,db).base.widthScale
    if desired==(metrics.widthScale or 1) then frame._fluxPendingNativeWidth=nil;return end
    -- Never dereference a restricted object's table or query native geometry.
    -- DenyTaintedAccessWhenAurasAreSecret is enforced by the native access predicate.
    for _,item in ipairs(frame._fluxNativeAuraGeometry or {}) do
        if Locked() or not canaccesstable or not canaccesstable(item.button) or not canaccesstable(item.text) then
            frame._fluxPendingNativeWidth=true;return
        end
    end
    for _,item in ipairs(frame._fluxNativeAuraGeometry or {}) do
        item.button:SetSize(item.height*desired,item.height)
        StyleDurationText(item.text,item.button,item.height*desired,nil,item.height)
    end
    metrics.widthScale,metrics.width=desired,11*desired
    frame._fluxPendingNativeWidth=nil
end
local function StyleCount(button)
    local text=button.Count;if not text then return end
    text:ClearAllPoints()
    text:SetFontObject(NumberFontNormal or "NumberFontNormal")
    text:SetPoint("BOTTOMRIGHT",button.Icon,"BOTTOMRIGHT",-2,2)
end
local function ConfigureDuration(cooldown,native,button,frame)
    if not native and cooldown.SetCountdownFormatter and FluxRaidVisuals.GetAuraDurationFormatter then
        cooldown:SetCountdownFormatter(FluxRaidVisuals.GetAuraDurationFormatter(nil,frame))
    end
    cooldown:SetHideCountdownNumbers(native and true or false)
    cooldown:SetAllPoints(button)
    cooldown:SetFrameLevel(button:GetFrameLevel()+1)
    if cooldown.SetDrawSwipe then cooldown:SetDrawSwipe(true) end
    if cooldown.SetSwipeTexture then cooldown:SetSwipeTexture("Interface\\Buttons\\WHITE8X8",0,0,0,1) end
    if cooldown.SetSwipeColor then cooldown:SetSwipeColor(0,0,0,FluxRaidVisuals.AURA_SWIPE_ALPHA or .75) end
    if cooldown.SetDrawEdge then cooldown:SetDrawEdge(false) end
    if cooldown.SetDrawBling then cooldown:SetDrawBling(false) end
    if cooldown.SetReverse then cooldown:SetReverse(true) end
    -- CooldownFrameTemplate starts hidden. Prepare its visibility before the
    -- native sink owns Shown; empty durations still have no active swipe.
    if native then cooldown:Show() end
    if not native and cooldown.GetCountdownFontString then
        local text=cooldown:GetCountdownFontString()
        if text then
            text:SetParent(button.AuraTextLayer or button)
            StyleDurationText(text,button,button:GetWidth())
            text:Hide(); button._fluxCountdownText=text
        end
    end
end
local function InitializeText(button)
    -- Prepare the XML-owned text host before native restrictions are applied.
    -- Cooldown is a child frame, so OVERLAY FontStrings on the button alone
    -- would still draw beneath its swipe.
    local host=button.AuraTextLayer
    if host then
        host:SetFrameLevel(button:GetFrameLevel()+3)
        if button.Duration then button.Duration:SetParent(host) end
        if button.Count then button.Count:SetParent(host) end
    end
end
local durationFormatter,durationFormatterChecked
local function NativeDurationFormatter(frame)
    local shared=FluxRaidVisuals.GetAuraDurationFormatter and FluxRaidVisuals.GetAuraDurationFormatter(nil,frame)
    if shared then return shared end
    if durationFormatterChecked then return durationFormatter end
    durationFormatterChecked=true
    local numericRounding=Enum and Enum.NumericRuleFormatRounding
    if C_StringUtil and C_StringUtil.CreateNumericRuleFormatter and numericRounding
        and numericRounding.Up~=nil and numericRounding.Down~=nil then
        local formatter=C_StringUtil.CreateNumericRuleFormatter()
        if formatter and formatter.SetBreakpoints then
            formatter:SetBreakpoints({
                {threshold=0,format="%d",step=1,rounding=numericRounding.Up},
                {threshold=60,format="%dm",step=1,rounding=numericRounding.Down,components={{div=60}}},
                {threshold=3600,format="%dh",step=1,rounding=numericRounding.Down,components={{div=3600}}},
                {threshold=86400,format="%dd",step=1,rounding=numericRounding.Down,components={{div=86400}}},
            })
            durationFormatter=formatter
            return formatter
        end
    end
    local abbreviation=Enum and Enum.SecondsFormatterAbbreviation
    local whitespace=Enum and Enum.SecondsFormatterIntervalWhitespace
    if not (C_StringUtil and C_StringUtil.CreateSecondsFormatter and abbreviation and whitespace
        and abbreviation.OneLetter~=nil and whitespace.StripIgnoreLocale~=nil) then return end
    local formatter=C_StringUtil.CreateSecondsFormatter()
    if not (formatter and formatter.SetDefaultAbbreviation and formatter.SetDesiredUnitCount
        and formatter.SetStripIntervalWhitespace) then return end
    -- This formatter belongs only to Flux. Native bindings format restricted
    -- remaining time directly; no shared formatter or aura value is inspected.
    formatter:SetDefaultAbbreviation(abbreviation.OneLetter)
    formatter:SetDesiredUnitCount(1)
    formatter:SetStripIntervalWhitespace(whitespace.StripIgnoreLocale)
    local rounding=Enum.SecondsFormatterRounding
    if formatter.SetRounding and rounding and rounding.Truncate~=nil then formatter:SetRounding(rounding.Truncate) end
    if formatter.SetCanRoundUpLastUnit then formatter:SetCanRoundUpLastUnit(true) end
    local interval=Enum.SecondsFormatterInterval
    if interval then
        if formatter.SetMinInterval and interval.Seconds~=nil then formatter:SetMinInterval(interval.Seconds) end
        if formatter.SetMaxInterval and interval.Days~=nil then formatter:SetMaxInterval(interval.Days) end
    end
    durationFormatter=formatter
    return formatter
end
local function InitializeNative(button,metrics,frame)
    button:SetSize(metrics.width,metrics.height); button:EnableMouse(false)
    InitializeText(button)
    ConfigureDuration(button.Cooldown,true,button,frame)
    StyleCount(button)
    assert(button.Duration and button.SetDurationText,"native aura duration text sink unavailable")
    StyleDurationText(button.Duration,button,metrics.width,metrics.durationFontScale); button.Duration:SetText("")
    button:SetIcon(button.Icon); button:SetDurationCooldown(button.Cooldown)
    local formatter=NativeDurationFormatter(frame)
    button:SetDurationText(button.Duration,formatter and {textFormatter=formatter} or nil)
    if button.SetApplicationCount and button.Count then button:SetApplicationCount(button.Count) end
end
local function DecorateDispel(button,frame,metrics)
    InitializeNative(button,metrics,frame)
    if not button.AddDispelTypeTexture then return end
    local parent=frame._fluxPartyMember and button.AuraTextLayer or button
    local edge=parent:CreateTexture(nil,frame._fluxPartyMember and "ARTWORK" or "OVERLAY",nil,frame._fluxPartyMember and 1 or 0)
    edge:SetAllPoints(button); edge:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
    edge:SetTexCoord(.296875,.5703125,0,.515625); button:AddDispelTypeTexture(edge)
end
local function InitializeDispelBorder(button,frame,parent)
    -- This single native slot stays outside the clipped icon blocks. Every
    -- color sink is a descendant of the native slot, and native assignment
    -- alone controls their visibility. No aura value is returned to addon Lua.
    button:SetAllPoints(frame); button:EnableMouse(false)
    if button.SetFrameLevel and parent.GetFrameLevel then button:SetFrameLevel(parent:GetFrameLevel()+2) end
    local style=Enum and Enum.CustomAuraButtonDispelTypeTextureStyle
    local options=style and {style=style.PreserveAsset} or nil
    for _,point in ipairs({"TOP","BOTTOM","LEFT","RIGHT"}) do
        local texture=button:CreateTexture(nil,"OVERLAY"); texture:SetColorTexture(1,1,1,.8)
        if point=="TOP" or point=="BOTTOM" then
            local y=point=="TOP" and -2 or 6
            texture:SetHeight(2); texture:SetPoint(point.."LEFT",frame,point.."LEFT",2,y); texture:SetPoint(point.."RIGHT",frame,point.."RIGHT",-2,y)
        else
            local x=point=="LEFT" and 2 or -2
            texture:SetWidth(2); texture:SetPoint("TOP"..point,frame,"TOP"..point,x,-2); texture:SetPoint("BOTTOM"..point,frame,"BOTTOM"..point,x,6)
        end
        button:AddDispelTypeTexture(texture,options)
    end
end
local function NewContainer(row,right)
    local box=CreateFrame("AuraContainer",nil,row,"CustomAuraContainerTemplate")
    local anchor=right and "TOPRIGHT" or "TOPLEFT"
    box:SetPoint(anchor,row,anchor,0,0); box:SetFlowLayoutAnchorPoint(anchor)
    box:SetFlowLayoutAxis(AnchorUtil.FlowLayoutAxis.Vertical)
    box:SetFlowLayoutGrowthDirection(right and AnchorUtil.FlowDirection.Left or AnchorUtil.FlowDirection.Right,AnchorUtil.FlowDirection.Down)
    box:SetFlowLayoutPadding(0,0,0,0); box:EnableMouse(false)
    if box.SetEditModePreviewEnabled then box:SetEditModePreviewEnabled(false) end
    return box
end
local function AddGroup(box,key,filter,metrics,index,candidates,initialize,sort)
    box:AddAuraGroup(key,filter,{maxFrameCount=SLOTS,templateNames={"FluxRaidAuraIconTemplate"},
        initializeFrame=initialize,candidateFilters=candidates,sortMethod=sort,
        layout={layoutIndex=index,elementSpacing=metrics.gap,lineSpacing=metrics.gap,groupSpacing=0,
            groupLineSpacing=metrics.gap,forceNewLine=false,elementWidth=metrics.width,elementHeight=metrics.height}})
end
local function BuildNative(frame)
    local kinds=AuraUtil and AuraUtil.AuraUpdateChangedType
    if not (AnchorUtil and AnchorUtil.FlowDirection and AnchorUtil.FlowLayoutAxis and AuraContainerSortMethod
        and CustomAuraContainerAuraProcessingPolicy and kinds and kinds.Buff and kinds.Debuff and kinds.Dispel) then return false end
    -- Native icon creation is independent of the saved size. Later edits scale
    -- only public containers, so reload history cannot change the fitted result.
    local geometry=Dimensions(frame)
    local rows,metrics=EnsureRows(frame),geometry.base
    local client=ns.Flux and ns.Flux.Client
    local largeHelpful=client and client.isAnyClassic==true
    local boxes,buttons,initializerError={},frame._fluxNativeAuraButtons or {},nil
    frame._fluxNativeAuraButtons=buttons
    frame._fluxAuraContainers=boxes -- Exclude even partial native subtrees from binding discovery.
    local function guarded(callback)
        return function(button)
            -- The native provider uses securecallfunction for this callback,
            -- so its errors do not propagate to BuildNative's outer pcall.
            local ok,message=pcall(callback,button)
            if not ok then initializerError=initializerError or tostring(message) end
        end
    end
    local function initializer(large,decorated,debuff)
        local size=large and geometry.largeRoleEnabled and (metrics.largeIconSize or FluxRaidVisuals.GetBlizzardDefaultSizing().largeIconSize)
        local iconMetrics={width=size and size*(metrics.widthScale or 1) or metrics.width,height=size or metrics.height,gap=metrics.gap,durationFontScale=metrics.durationFontScale}
        return guarded(function(button)
            if debuff and frame._fluxPartyMember then
                InitializeNative(button,iconMetrics,frame)
                local edge=FluxRaidVisuals.EnsurePartyDebuffBorder(button,frame)
                local styles=Enum and Enum.CustomAuraButtonDispelTypeTextureStyle
                -- Classic's SetAuraBorderAtlas only tints the original asset;
                -- PreserveAsset keeps that color instead of resetting it white.
                local borderStyle=client and client.isAnyClassic and styles and styles.PreserveAsset or styles and styles.Border or 0
                if button.AddDispelTypeTexture then
                    button:AddDispelTypeTexture(edge,{style=borderStyle,showWithoutDispelType=true})
                end
            elseif decorated then DecorateDispel(button,frame,iconMetrics)
            else InitializeNative(button,iconMetrics,frame) end
            buttons[#buttons+1]=button
            frame._fluxNativeAuraGeometry=frame._fluxNativeAuraGeometry or {}
            frame._fluxNativeAuraGeometry[#frame._fluxNativeAuraGeometry+1]={button=button,text=button.Duration,height=iconMetrics.height}
        end)
    end
    local initialize=initializer(false,false)
    local ok,setupError=pcall(function()
        local function create(key,parent,right)
            local _,anchor=FluxRaidVisuals.GetFrameAuraAnchor(frame,right)
            local box=NewContainer(parent,anchor=="TOPRIGHT"); boxes[key]=box
            box:SetAuraProcessingPolicy(CustomAuraContainerAuraProcessingPolicy.ProcessAura,{displayOnlyDispellableDebuffs=false})
            local side=right and geometry.buffs or geometry.debuffs
            local layoutMetrics={width=side.baseSlotWidth or (side.slotWidth or side.width)/geometry.scale,
                height=side.baseSlotHeight or (side.slotHeight or side.height)/geometry.scale,gap=metrics.gap}
            if right then
                AddGroup(box,"raidBuffs","HELPFUL",layoutMetrics,1,{processedAuraType=kinds.Buff},initialize,AuraContainerSortMethod.Default)
                AddGroup(box,"classBuffs","HELPFUL",layoutMetrics,2,{includeSpellIDs=ClassBuffFilter()},initialize,AuraContainerSortMethod.Default)
                if initializerError then error(initializerError) end
                return box
            end
            local decorated=not key:find("Plain",1,true)
            local dispelInit=initializer(false,decorated,true)
            -- Public groups accept one processed class at a time. These
            -- disjoint groups reproduce native UnitFrameDebuffType priority:
            -- boss harmful, boss helpful, priority, raid dispel, ordinary.
            -- Boss harmful accepts both native Debuff and Dispel classes;
            -- both receive BossDebuff metadata from the native policy.
            AddGroup(box,"bossDebuffs","HARMFUL",layoutMetrics,1,{isBossOrRoleAura=true},initializer(true,decorated,true),AuraContainerSortMethod.UnitFrameDebuff)
            AddGroup(box,"bossBuffs","HELPFUL",layoutMetrics,2,{processedAuraType=kinds.Debuff},initializer(largeHelpful,false,true),AuraContainerSortMethod.UnitFrameDebuff)
            AddGroup(box,"priorityDebuffs","HARMFUL",layoutMetrics,3,{processedAuraType=kinds.Debuff,isBossOrRoleAura=false,isPriorityAura=true},dispelInit,AuraContainerSortMethod.UnitFrameDebuff)
            AddGroup(box,"dispel","HARMFUL|RAID",layoutMetrics,4,{processedAuraType=kinds.Dispel,isBossOrRoleAura=false},dispelInit,AuraContainerSortMethod.UnitFrameDebuff)
            AddGroup(box,"debuffs","HARMFUL",layoutMetrics,5,{processedAuraType=kinds.Debuff,isBossOrRoleAura=false,isPriorityAura=false},dispelInit,AuraContainerSortMethod.UnitFrameDebuff)
            if initializerError then error(initializerError) end
            return box
        end
        frame._fluxCreateAuraBox=create
        create("buffs",rows.top.primary,true)
        create("dispel",rows.bottom.primary)
        create("dispelPlain",rows.bottom.primary)
        local parent=frame._fluxHighlightLayer or frame._fluxTextLayer or frame
        local border=CreateFrame("AuraContainer",nil,parent,"CustomAuraContainerTemplate")
        boxes.dispelBorder=border
        border:SetAllPoints(frame); border:EnableMouse(false)
        if border.SetFrameLevel and parent.GetFrameLevel then border:SetFrameLevel(parent:GetFrameLevel()+1) end
        if border.SetEditModePreviewEnabled then border:SetEditModePreviewEnabled(false) end
        border:SetAuraProcessingPolicy(CustomAuraContainerAuraProcessingPolicy.ProcessAura,{displayOnlyDispellableDebuffs=true})
        border:AddAuraSlot("dispel","HARMFUL|RAID",{templateNames={"FluxRaidDispelBorderTemplate"},
            initializeFrame=guarded(function(button) InitializeDispelBorder(button,frame,parent) end),
            candidateFilters={processedAuraType=kinds.Dispel},sortMethod=AuraContainerSortMethod.UnitFrameDebuff})
        if initializerError then error(initializerError) end
        for _,box in pairs(boxes) do box:SetUnit("none"); box:Hide() end
    end)
    if not ok then
        frame._fluxAuraNativeError=tostring(setupError)
        for _,box in pairs(boxes) do if box.SetUnit then box:SetUnit("none") end; box:Hide() end
        return false
    end
    frame._fluxAuraNative,frame._fluxAuraNativeMetrics=true,metrics
    frame._fluxAuraNativeState={groups={},units={},strict={}}
    return true
end
EnsureNativeTails=function(frame,geometry)
    for _,spec in ipairs({{"top","buffs",true},{"bottom","dispel"},{"bottom","dispelPlain"}}) do
        local side=spec[3] and geometry.buffs or geometry.debuffs
        local key=spec[2].."Tail"
        if (side.count==3 or side.count==5) and not frame._fluxAuraContainers[key] then
            local row=frame._fluxAuraRows[spec[1]]
            if not row.tail then
                row.tail=CreateFrame("Frame",nil,row)
                row.tail:EnableMouse(false); row.tail:SetClipsChildren(true)
            end
            -- Native API exposes per-category caps, not a combined cap. A
            -- second deterministic owner paints the same sorted sequence through
            -- a partial final-column viewport, without inspecting native children.
            local box=frame._fluxCreateAuraBox(key,row.tail,spec[3])
            local _,anchor=FluxRaidVisuals.GetFrameAuraAnchor(frame,spec[3])
            box:ClearAllPoints(); box:SetPoint(anchor,row,anchor,0,0)
            box:SetUnit("none"); box:Hide()
            frame._fluxAuraNativeState.classBuffs=nil
        end
    end
end
local function BuildReadable(frame)
    local rows=EnsureRows(frame)
    local lists={buffs={},debuffs={}}
    for key,list in pairs(lists) do
        local parent=key=="buffs" and rows.top or rows.bottom
        for i=1,SLOTS do
            local icon=CreateFrame("Frame",nil,parent,"FluxRaidAuraIconTemplate")
            icon:EnableMouse(false); InitializeText(icon); ConfigureDuration(icon.Cooldown,false,icon,frame)
            if key=="debuffs" then FluxRaidVisuals.EnsurePartyDebuffBorder(icon,frame) end
            if icon.Duration then icon.Duration:SetText("") end
            icon:Hide(); list[i]=icon
        end
    end
    frame._fluxAuraCorners=lists
    frame.buffFrames,frame.debuffFrames,frame.dispelDebuffFrames=lists.buffs,lists.debuffs,lists.debuffs
end
local function ConfigureReadable(frame)
    local metrics=frame._fluxAuraRowMetrics
    for key,list in pairs(frame._fluxAuraCorners) do
        local side=metrics[key]
        local _,anchor=FluxRaidVisuals.GetFrameAuraAnchor(frame,key=="buffs")
        local right=anchor=="TOPRIGHT"
        for i,icon in ipairs(list) do
            icon:SetSize(side.width,side.height); icon:ClearAllPoints()
            icon._fluxAuraRenderScale=metrics.scale
            icon._fluxAuraPaintWidth,icon._fluxAuraPaintHeight=side.width,side.height
            StyleCount(icon)
            if icon._fluxCountdownText then StyleDurationText(icon._fluxCountdownText,icon,side.width) end
            local offset=floor((i-1)/side.rows)*((side.slotWidth or side.width)+side.gap)
            local y=-((i-1)%side.rows)*((side.slotHeight or side.height)+side.gap)
            icon:SetPoint(anchor,icon:GetParent(),anchor,right and -offset or offset,y)
        end
    end
end
function A.Setup(frame)
    if not frame or frame._fluxRaidMini then return false end
    if frame._fluxHealerAuras then return true end
    if Locked() then frame._fluxNeedsPrivateAuraSync=true; return true end
    if not BuildNative(frame) then BuildReadable(frame) end
    ConfigureRows(frame)
    if frame._fluxAuraCorners then ConfigureReadable(frame) end
    frame._fluxHealerAuras,frame._fluxNeedsPrivateAuraSync=true,nil
    return true
end
local function SetGroup(frame,key,group,enabled)
    local state=frame._fluxAuraNativeState.groups
    local id=key..":"..group
    if state[id]~=enabled then frame._fluxAuraContainers[key]:SetAuraGroupEnabled(group,enabled); state[id]=enabled end
end
local function BindBox(frame,key,unit,enabled)
    local state=frame._fluxAuraNativeState.units
    local token=enabled and unit or "none"
    local box=frame._fluxAuraContainers[key]
    if state[key]~=token then box:SetUnit(token); state[key]=token end
    box:SetShown(enabled)
end
local function UpdateNative(frame,unit,valid,opt)
    local buffs=valid and opt.displayBuffs~=false
    local classBuffs=buffs and ShowClassBuffs()
    local geometry=frame._fluxAuraRowMetrics
    if frame._fluxAuraNativeState.classBuffs~=classBuffs or frame._fluxAuraNativeState.hiddenRevision~=hiddenRevision then
        for _,key in ipairs(BUFF_BOXES) do
            local box=frame._fluxAuraContainers[key]
            if box then
                box:SetAuraGroupCandidateFilters("raidBuffs",{
                    processedAuraType=AuraUtil.AuraUpdateChangedType.Buff,excludeSpellIDs=BuffExclusions(classBuffs)})
                box:SetAuraGroupCandidateFilters("classBuffs",{includeSpellIDs=ClassBuffFilter()})
            end
        end
        frame._fluxAuraNativeState.classBuffs=classBuffs
        frame._fluxAuraNativeState.hiddenRevision=hiddenRevision
    end
    for _,key in ipairs(BUFF_BOXES) do
        if frame._fluxAuraContainers[key] then
            local enabled=buffs and (key=="buffs" or geometry.buffs.count==3 or geometry.buffs.count==5)
            SetGroup(frame,key,"classBuffs",enabled and classBuffs)
            SetGroup(frame,key,"raidBuffs",enabled); BindBox(frame,key,unit,enabled)
        end
    end
    local highlight=not FluxRaid_IsDispelHighlightEnabled or FluxRaid_IsDispelHighlightEnabled()
    local strict=opt.displayOnlyDispellableDebuffs==true
    for _,key in ipairs(DEBUFF_BOXES) do
        if frame._fluxAuraContainers[key] then
            local tail=key:find("Tail",1,true)~=nil
            local decorated=not key:find("Plain",1,true)
            local enabled=valid and opt.displayDebuffs~=false and decorated==highlight
                and (not tail or geometry.debuffs.count==3 or geometry.debuffs.count==5)
            if frame._fluxAuraNativeState.strict[key]~=strict then
                -- Strict mode enables only HARMFUL|RAID across the chosen limit;
                -- boss, own and priority categories cannot bypass this filter.
                local candidates
                if strict then candidates={isBossOrRoleAura=false}
                elseif not strict then candidates={processedAuraType=AuraUtil.AuraUpdateChangedType.Dispel,isBossOrRoleAura=false} end
                frame._fluxAuraContainers[key]:SetAuraGroupCandidateFilters("dispel",candidates)
                frame._fluxAuraContainers[key]:SetAuraGroupFilterString("bossDebuffs",strict and "HARMFUL|RAID" or "HARMFUL")
                frame._fluxAuraNativeState.strict[key]=strict
            end
            SetGroup(frame,key,"dispel",enabled)
            SetGroup(frame,key,"bossDebuffs",enabled)
            for _,group in ipairs({"bossBuffs","priorityDebuffs","debuffs"}) do
                SetGroup(frame,key,group,enabled and not strict)
            end
            BindBox(frame,key,unit,enabled)
        end
    end
    BindBox(frame,"dispelBorder",unit,valid and opt.displayDebuffs~=false and highlight)
    frame._fluxAuraRows.top:SetShown(buffs)
    frame._fluxAuraRows.bottom:SetShown(valid and opt.displayDebuffs~=false)
end
local function ReadAura(unit,index,filter)
    local data
    local api=ns.Flux and ns.Flux.Aura
    if api and api.GetDataByIndex then data=api.GetDataByIndex(unit,index,filter)
    elseif C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        local ok,result=pcall(C_UnitAuras.GetAuraDataByIndex,unit,index,filter); if ok then data=result end
    elseif UnitAura then
        local name,icon,count,dispel,duration,expiration,source,_,_,id,canApply,boss=UnitAura(unit,index,filter)
        if Readable(name) and name then data={name=name,icon=icon,applications=count,dispelName=dispel,
            duration=duration,expirationTime=expiration,sourceUnit=source,spellId=id,isBossAura=boss,canApplyAura=canApply} end
    end
    if not Readable(data) or type(data)~="table" then return end
    if Readable(data.auraInstanceID) and data.auraInstanceID==nil
        and Readable(data.isHelpful) and data.isHelpful==nil and Readable(data.isHarmful) and data.isHarmful==nil then
        -- UnitAura has no instance identity. Use only proven query context;
        -- retain its ordering locally without inventing an API instance ID.
        local copy={};for key,value in pairs(data) do copy[key]=value end
        copy.isHelpful=filter:find("HELPFUL",1,true)~=nil
        copy.isHarmful=not copy.isHelpful;copy.isRaid=filter:find("|RAID",1,true)~=nil
        copy._fluxQueryOrder=index
        return copy
    end
    return data
end
local function Key(aura)
    if aura._fluxQueryOrder then
        if not Readable(aura.spellId) or not Readable(aura.sourceUnit) or not Readable(aura.name) then return end
        return "legacy:"..tostring(aura.isHelpful)..":"..tostring(aura.spellId or aura.name)..":"..tostring(aura.sourceUnit)
    end
    for _,field in ipairs({"auraInstanceID","spellId","name"}) do
        local value=aura[field]
        if not Readable(value) then return nil end
        if value~=nil then return field..":"..tostring(value) end
    end
end
local function Scan(unit,filter,accept)
    local list={}
    local i=1
    while true do
        local aura=ReadAura(unit,i,filter); if not aura then break end
        if not accept or accept(aura) then list[#list+1]=aura end
        i=i+1
    end
    return list
end
local CLASSIFY_FIELDS={"auraInstanceID","spellId","sourceUnit","isNameplateOnly","isBossAura","isRaid",
    "isHarmful","isHelpful","canApplyAura","isTankRoleAura","isHealerRoleAura","isDPSRoleAura",
    "dispelName","isPriorityAura","hideOnPartyFrames"}
local SORT_FIELDS={"auraInstanceID","sourceUnit","isPriorityAura","canApplyAura","debuffType"}
local function CopyReadableAura(aura)
    for _,field in ipairs(CLASSIFY_FIELDS) do if not Readable(aura[field]) then return end end
    for _,field in ipairs(SORT_FIELDS) do if not Readable(aura[field]) then return end end
    if aura.hideOnPartyFrames then return end
    if aura.auraInstanceID~=nil and type(aura.auraInstanceID)~="number" then return end
    -- Work on a private copy; the shared aura service may cache the API table.
    local copy={}; for key,value in pairs(aura) do copy[key]=value end
    return copy
end
local function Classify(aura)
    if not (AuraUtil and AuraUtil.ProcessAura) then return end
    local copy=CopyReadableAura(aura); if not copy then return end
    local ok,kind=pcall(AuraUtil.ProcessAura,copy,false,false,false,false)
    if ok and Readable(kind) then
        for _,field in ipairs(SORT_FIELDS) do if not Readable(copy[field]) then return end end
        if copy.auraInstanceID==nil and not copy._fluxQueryOrder then return end
        return copy,kind
    end
end
local function StrictRaidAura(aura)
    local copy=CopyReadableAura(aura)
    local types=AuraUtil and AuraUtil.UnitFrameDebuffType
    if not copy or not types then return end
    -- HARMFUL|RAID membership is authoritative for the user's strict mode.
    -- Custom spell visibility cannot remove an otherwise dispellable aura.
    local boss=copy.isBossAura or (AuraUtil.IsRoleAura and AuraUtil.IsRoleAura(copy))
    copy.debuffType=boss and types.BossDebuff or types.NonBossRaidDebuff
    return copy
end
local function AddUnique(output,seen,aura)
    local key=Key(aura)
    if not key then return end
    local index=seen[key]
    if not index then output[#output+1]=aura;seen[key]=#output
    elseif type(index)=="number" then
        local old=output[index]
        if type(aura.debuffType)=="number" and type(old.debuffType)=="number" and aura.debuffType<old.debuffType then output[index]=aura end
    end
end
local function Sort(auras,debuffs)
    local compare=AuraUtil and (debuffs and AuraUtil.UnitFrameDebuffComparator or AuraUtil.DefaultAuraCompare)
    if compare then table.sort(auras,function(a,b)
        if a.auraInstanceID~=nil and b.auraInstanceID~=nil then return compare(a,b) end
        if debuffs and a.debuffType~=b.debuffType then return a.debuffType<b.debuffType end
        local ownA,ownB=a.sourceUnit=="player",b.sourceUnit=="player"
        if ownA~=ownB then return ownA end
        if a.isPriorityAura~=b.isPriorityAura then return a.isPriorityAura==true end
        if a.canApplyAura~=b.canApplyAura then return a.canApplyAura==true end
        return (a._fluxQueryOrder or 0)<(b._fluxQueryOrder or 0)
    end) end
end
local function Append(output,seen,list)
    for _,aura in ipairs(list) do
        local key=Key(aura)
        if key and not seen[key] then
            seen[key]=true; output[#output+1]=aura
            if #output==SLOTS then return end
        end
    end
end
local function PaintList(list,auras,limit,geometry,side)
    for i,icon in ipairs(list) do
        local aura=i<=limit and auras[i]
        if not aura or not Readable(aura.icon) or not aura.icon then icon:Hide()
        else
            if geometry.nativeDefaults then
                local large=false
                local fields={"isBossAura","isTankRoleAura","isHealerRoleAura","isDPSRoleAura","isHarmful"}
                local accessible=true;for _,field in ipairs(fields) do if not Readable(aura[field]) then accessible=false;break end end
                if accessible and geometry.largeRoleEnabled then
                    local client=ns.Flux and ns.Flux.Client
                    large=(aura.isBossAura or aura.isTankRoleAura or aura.isHealerRoleAura or aura.isDPSRoleAura)
                        and (aura.isHarmful or client and client.isAnyClassic==true)
                end
                local width,height=large and geometry.largeIconSize*(geometry.base.widthScale or 1) or side.width,large and geometry.largeIconSize or side.height
                if icon._fluxAuraPaintWidth~=width or icon._fluxAuraPaintHeight~=height then
                    icon:SetSize(width,height);icon._fluxAuraPaintWidth,icon._fluxAuraPaintHeight=width,height
                    if icon._fluxCountdownText then StyleDurationText(icon._fluxCountdownText,icon,width) end
                end
            end
            icon.Icon:SetTexture(aura.icon)
            if icon._fluxPartyDebuffBorder then
                local kind=Readable(aura.dispelName) and aura.dispelName
                if Readable(aura.isHelpful) and aura.isHelpful==true then icon._fluxPartyDebuffBorder:Hide()
                else
                    FluxRaidVisuals.SetPartyDebuffBorderType(icon,kind)
                    icon._fluxPartyDebuffBorder:Show()
                end
            end
            local n=aura.applications; icon.Count:SetText(Readable(n) and type(n)=="number" and n>1 and n or "")
            local duration,expiration=aura.duration,aura.expirationTime
            if Readable(duration) and Readable(expiration) and type(duration)=="number" and type(expiration)=="number" and duration>0 then
                icon.Cooldown:SetCooldown(expiration-duration,duration)
                icon.Cooldown:Show()
                if icon._fluxCountdownText then icon._fluxCountdownText:Show() end
            else
                icon.Cooldown:SetCooldown(0,0); icon.Cooldown:Hide()
                if icon._fluxCountdownText then icon._fluxCountdownText:Hide() end
            end
            icon:Show()
        end
    end
end
function A.Update(frame)
    if not frame or frame._fluxRaidMini then return end
    A.Setup(frame); if not frame._fluxHealerAuras then return end
    local unit,opt=Unit(frame),frame.optionTable or {}
    local valid=type(unit)=="string" and unit~=""
    if frame._fluxAuraNative then UpdateNative(frame,unit,valid,opt); return end
    local buffs,debuffs,dispel={},{},{}
    local buffSeen,debuffSeen={},{}
    local kinds=AuraUtil and AuraUtil.AuraUpdateChangedType
    local ids,names=ClassBuffFilter()
    local classBuffs=ShowClassBuffs()
    -- Match the client's spell/spec visibility and ordering, including boss
    -- helpful auras on the debuff side. Duration never decides eligibility.
    if valid and kinds then
        for _,filter in ipairs({"HARMFUL","HARMFUL|RAID","HELPFUL"}) do
            for _,aura in ipairs(Scan(unit,filter)) do
                local copy,kind=Classify(aura)
                if copy then
                    if kind==kinds.Buff and opt.displayBuffs~=false and not HiddenBuffs()[copy.spellId]
                        and not (classBuffs and ids[copy.spellId]) then AddUnique(buffs,buffSeen,copy)
                    elseif (kind==kinds.Debuff or kind==kinds.Dispel) and opt.displayDebuffs~=false
                        and opt.displayOnlyDispellableDebuffs~=true then AddUnique(debuffs,debuffSeen,copy) end
                end
            end
        end
        Sort(buffs,false); Sort(debuffs,true)
    end
    if valid and opt.displayBuffs~=false then
        if classBuffs and #buffs<SLOTS then Append(buffs,buffSeen,Scan(unit,"HELPFUL",function(aura)
            local id,name=aura.spellId,aura.name
            return Readable(id) and Readable(aura.hideOnPartyFrames) and not aura.hideOnPartyFrames
                and ((id~=nil and ids[id]) or (Readable(name) and name~=nil and names[name]))
        end)) end
    end
    if valid and opt.displayDebuffs~=false then
        dispel=Scan(unit,"HARMFUL|RAID",function(aura)
            return Readable(aura.canActivePlayerDispel) and aura.canActivePlayerDispel~=false
                and Readable(aura.hideOnPartyFrames) and not aura.hideOnPartyFrames
        end)
        if opt.displayOnlyDispellableDebuffs==true then
            for _,aura in ipairs(dispel) do
                local copy=StrictRaidAura(aura)
                if copy then AddUnique(debuffs,debuffSeen,copy) end
            end
            Sort(debuffs,true)
        end
    end
    local geometry=frame._fluxAuraRowMetrics
    PaintList(frame._fluxAuraCorners.buffs,buffs,geometry.buffs.count,geometry,geometry.buffs)
    PaintList(frame._fluxAuraCorners.debuffs,debuffs,geometry.debuffs.count,geometry,geometry.debuffs)
    frame._fluxAuraRows.top:SetShown(valid and opt.displayBuffs~=false)
    frame._fluxAuraRows.bottom:SetShown(valid and opt.displayDebuffs~=false)
    local kind=dispel[1] and dispel[1].dispelName; frame._fluxDispelType=Readable(kind) and kind or nil
end
function A.UpdateDispel(frame)
    local highlight=frame.dispelHighlight; if not highlight then return end
    if frame._fluxAuraNative or (FluxRaid_IsDispelHighlightEnabled and not FluxRaid_IsDispelHighlightEnabled()) then highlight:Hide(); return end
    local kind=frame._fluxDispelType; local color=Readable(kind) and TYPE_COLORS[kind]
    if not color then highlight:Hide(); return end
    if highlight.fill then highlight.fill:SetVertexColor(color[1],color[2],color[3],.12) end
    if highlight.border then highlight.border:SetVertexColor(color[1],color[2],color[3]) end
    highlight:Show()
end
function A.Refresh(frame)
    if not frame or not frame._fluxHealerAuras then return end
    if Locked() then frame._fluxNeedsPrivateAuraSync=true; return end
    if FluxRaidVisuals.GetAuraDurationFormatter then FluxRaidVisuals.GetAuraDurationFormatter(nil,frame) end
    ConfigureRows(frame)
    if frame._fluxAuraNative then
        frame._fluxAuraNativeState.classBuffs=nil
    else ConfigureReadable(frame) end
    frame._fluxNeedsPrivateAuraSync=frame._fluxPendingNativeWidth or nil; A.Update(frame)
end
function A.Clear(frame)
    if not frame then return end
    RetireOwners(frame)
    for _,list in pairs(frame._fluxAuraCorners or {}) do for _,icon in ipairs(list) do icon:Hide() end end
    for _,row in pairs(frame._fluxAuraRows or {}) do row:Hide() end
    if frame._fluxAuraNativeState then frame._fluxAuraNativeState.units={} end
    frame._fluxDispelType=nil
    if frame.dispelHighlight then frame.dispelHighlight:Hide() end
end
function A.Diagnostics()
    local selected,prepared
    if FluxRaid_ForEachHeaderChild then FluxRaid_ForEachHeaderChild(function(frame)
        if not frame or frame._fluxRaidMini then return end
        prepared=prepared or frame
        local unit=Unit(frame)
        if not selected and Readable(unit) and type(unit)=="string" and unit~="" then selected=frame end
    end) end
    local frame=selected or prepared
    if not frame then return "aura-policy-20261106c: no prepared full cell" end
    local function scalar(value)
        if not Readable(value) then return "opaque" end
        return value==nil and "default" or tostring(value)
    end
    local state=frame._fluxAuraNativeState or {}
    local db=FluxOptions and FluxOptions.GetRaidFrameDB and FluxOptions:GetRaidFrameDB() or {}
    local row=frame._fluxAuraRows and frame._fluxAuraRows.top
    local shown=row and row.IsShown and row:IsShown()
    local reason=frame._fluxAuraNativeError
    if Readable(reason) and type(reason)=="string" then reason=reason:sub(1,140) end
    local hiddenCount=0;for _ in pairs(HiddenBuffs()) do hiddenCount=hiddenCount+1 end
    local classCount,hiddenClass=0,0
    for id in pairs(ClassBuffFilter()) do
        classCount=classCount+1
        if HiddenBuffs()[id] then hiddenClass=hiddenClass+1 end
    end
    local groups=state.groups or {}
    return "aura-policy-20261106c: native="..scalar(frame._fluxAuraNative).." ready="..scalar(frame._fluxHealerAuras)
        .." buffs="..scalar((frame.optionTable or {}).displayBuffs).." class="..scalar(db.showClassBuffs)
        .." normalGroup="..scalar(groups["buffs:raidBuffs"]).." classGroup="..scalar(groups["buffs:classBuffs"])
        .." classOOC="..scalar(ShowClassBuffs()).." hidden="..hiddenCount
        .." classIDs="..classCount.." hiddenClass="..hiddenClass
        .." alpha="..scalar(FluxRaidVisuals.AURA_ICON_ALPHA).." row="..scalar(shown)
        .." bound="..scalar(state.units and state.units.buffs).." width="..scalar(frame._fluxAuraNativeMetrics and frame._fluxAuraNativeMetrics.widthScale).." pendingWidth="..scalar(frame._fluxPendingNativeWidth).." error="..scalar(reason)
end
function A.DebugDuration()
    if Locked() then return "aura-clock-probe1: out of combat only" end
    if not (CreateFrame and GetTime and C_DurationUtil and C_DurationUtil.CreateDuration) then
        return "aura-clock-probe1: own duration API unavailable"
    end
    local probe=A._durationDebug
    local function scalar(value)
        if not Readable(value) then return "opaque" end
        if value==true then return "1" elseif value==false then return "0" end
        if type(value)=="string" then return value:gsub("[%c|]","?"):sub(1,18) end
        return value==nil and "nil" or tostring(value)
    end
    local function cleanup()
        if not probe then return end
        if probe.cooldown then
            if probe.cooldown.Clear then pcall(probe.cooldown.Clear,probe.cooldown) end
            pcall(probe.cooldown.Hide,probe.cooldown)
        end
        if probe.parent then pcall(probe.parent.Hide,probe.parent) end
    end
    local ok,result=pcall(function()
        if not probe then
            probe={};A._durationDebug=probe
            -- This isolated owner never receives a unit, aura, secure binding,
            -- event or Lua update script. Its parent stays hidden throughout.
            probe.parent=CreateFrame("Frame",nil,UIParent)
            probe.parent:Hide();probe.parent:SetSize(10,15);probe.parent:EnableMouse(false)
            probe.cooldown=CreateFrame("Cooldown",nil,probe.parent,"CooldownFrameTemplate")
            probe.cooldown:SetAllPoints(probe.parent);probe.cooldown:EnableMouse(false)
            probe.text=probe.parent:CreateFontString(nil,"OVERLAY")
            -- No anchors: measuring known text cannot inherit secret geometry.
            probe.text:SetWidth(12);probe.text:SetWordWrap(false)
            probe.duration=C_DurationUtil.CreateDuration()
        end
        local cd,duration=probe.cooldown,probe.duration
        if not (cd and cd.SetCooldownFromDurationObject and cd.SetCooldown and cd.Clear and cd.IsShown
            and duration and duration.SetTimeFromStart and duration.SetTimeSpan and probe.text) then
            return "aura-clock-probe1: own widget methods unavailable"
        end
        local now=GetTime()
        if not Readable(now) or type(now)~="number" then return "aura-clock-probe1: plain clock unavailable" end
        cd:Clear();cd:Hide();cd:SetDrawSwipe(true);cd:SetReverse(true)
        cd:SetSwipeColor(0,0,0,.75)
        local before=scalar(cd:IsShown())
        -- Every setter input is a public, literal-owned duration. No native
        -- aura sink or restricted duration object is queried or modified.
        duration:SetTimeFromStart(now-5,30)
        cd:SetCooldownFromDurationObject(duration,true)
        local positive=scalar(cd:IsShown())
        duration:SetTimeSpan(0,0);cd:SetCooldownFromDurationObject(duration,true)
        local zero=scalar(cd:IsShown())
        duration:SetTimeFromStart(now-5,30);cd:SetCooldownFromDurationObject(duration,true)
        local again=scalar(cd:IsShown())
        cd:Show()
        local seededStart=scalar(cd:IsShown())
        duration:SetTimeSpan(0,0);cd:SetCooldownFromDurationObject(duration,true)
        local seededZero=scalar(cd:IsShown())
        duration:SetTimeFromStart(now-5,30);cd:SetCooldownFromDurationObject(duration,true)
        local seededPositive=scalar(cd:IsShown())
        cd:Clear();cd:Hide()
        local numericBefore=scalar(cd:IsShown())
        cd:SetCooldown(now-5,30)
        local numericAfter=scalar(cd:IsShown())
        local swipe=cd.GetDrawSwipe and scalar(cd:GetDrawSwipe()) or "unavailable"
        local reverse=cd.GetReverse and scalar(cd:GetReverse()) or "unavailable"
        local formatted={}
        local formatter=NativeDurationFormatter()
        for _,seconds in ipairs({59,90,1800}) do
            formatted[#formatted+1]=formatter and formatter.FormatNumber and scalar(formatter:FormatNumber(seconds)) or "unavailable"
        end
        local text=probe.text
        local font=FluxRaidVisuals.AURA_DURATION_FONT_SIZE or 9
        text:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",font,"OUTLINE")
        local fits={}
        for _,sample in ipairs({"9","59","30s"}) do
            text:SetText(sample)
            local width=text.GetUnboundedStringWidth and text:GetUnboundedStringWidth()
                or (text.GetStringWidth and text:GetStringWidth())
            if Readable(width) and type(width)=="number" then width=floor(width*10+.5)/10 end
            local truncated=text.IsTruncated and scalar(text:IsTruncated()) or "unavailable"
            fits[#fits+1]=sample..":"..scalar(width).."/"..truncated
        end
        return "aura-clock-probe1: show="..before.."/"..positive.."/"..zero.."/"..again
            .." seeded="..seededStart.."/"..seededZero.."/"..seededPositive
            .." numeric="..numericBefore.."/"..numericAfter.." style="..swipe.."/"..reverse
            .." fmt="..table.concat(formatted,",").." font="..scalar(font).."w12 fit="..table.concat(fits,",")
    end)
    cleanup()
    if ok then return result end
    if Readable(result) and type(result)=="string" then result=result:gsub("[%c|]","?"):sub(-100)
    else result=scalar(result) end
    return "aura-clock-probe1: own widget error="..result
end
