-- Execute pinned native setup and setting conversion code against public owned
-- widgets. This establishes sizing equations, not native rendering or taint.
local root=(arg[0]:match("^(.*)[/\\]")or".").."/../"
local cache=os.getenv("FLUX_RAID_DEFAULT_SIZE_CACHE")or
    "C:/Users/mario/.codex/visualizations/2026/11/06/01a1b0ac-547f-7972-8df9-fa26882e0e03/raid-native-default-size-20261107"
local function read(path)local f=assert(io.open(path,"rb"),path);local s=f:read("*a"):gsub("\r\n","\n");f:close();return s end
local code=read(os.getenv("FLUX_RAID_VISUALS_SOURCE")or root.."RaidFrame/FluxRaidVisuals.lua")
local checks=0
local function check(value,label)checks=checks+1;assert(value,label)end
local function near(a,b)return type(a)=="number"and type(b)=="number"and math.abs(a-b)<1e-8 end
local methods={}
local function widget(parent)return setmetatable({parent=parent,points={},level=1,shown=true},{__index=function(self,key)
    if methods[key]then return methods[key]end
    if type(key)=="string"and (key:match("^Set")or key:match("^Get")or key:match("^Initialize")or key:match("^Update")or key:match("^Enable"))then return function()end end
end})end
function methods:ClearAllPoints()self.points={}end
function methods:SetPoint(...)self.points[#self.points+1]={...}end
function methods:SetAllPoints(other)self.allPoints=other end
function methods:SetParent(parent)self.parent=parent end
function methods:CreateTexture()return widget(self)end
function methods:CreateFontString()return widget(self)end
function methods:GetFrameLevel()return self.level end
function methods:SetFrameLevel(level)self.level=level end
function methods:SetSize(w,h)self.width,self.height=w,h end
function methods:SetWidth(w)self.width=w end
function methods:SetHeight(h)self.height=h end
function methods:GetWidth()return self.width or 98 end
function methods:GetHeight()return self.height or 17 end
function methods:SetShown(v)self.shown=v end
function methods:Show()self.shown=true end
function methods:Hide()self.shown=false end
function methods:IsShown()return self.shown end
function methods:SetTexture()return false end
function methods:SetStatusBarTexture()self.fill=self.fill or widget(self)end
function methods:GetStatusBarTexture()self.fill=self.fill or widget(self);return self.fill end
-- Native FontString-local height overrides can survive SetFontObject. Returning
-- that local height models the live repeated-refresh failure, unlike resetting
-- the mock's font size to its inherited object on every call.
function methods:SetFontObject(font)self.fontObject=font;self.font={font:GetFont()}end
function methods:GetFont()
    local font=self.font or {"KnownFont",12,""}
    return font[1],self.fontHeight or font[2],font[3]
end
function methods:SetFont(path,size,flags)self.font={path,size,flags};self.fontHeight=size end
function methods:SetFontHeight(size)self.fontHeight=size end
function methods:SetTextScale(scale)self.textScale=scale end
local function cell()
    local f=widget()
    for _,key in ipairs({"background","name","statusText","roleIcon","healthBar","powerBar","centerStatusIcon",
        "readyCheckIcon","myHealPrediction","otherHealPrediction","myHealAbsorb","myHealAbsorbOverlay","totalAbsorb",
        "totalAbsorbOverlay","overAbsorbGlow","overHealAbsorbGlow","TempMaxHealthLoss","pingIconFrame",
        "leaderIcon","masterLooterIcon","raidTargetIcon","selectionHighlight","mouseOverHighlight","aggroHighlight"})do f[key]=widget(f)end
    f.healthBar.background,f.powerBar.background=widget(f.healthBar),widget(f.powerBar)
    return f
end
local function source(client,path)return read(cache.."/"..client.."/Interface/AddOns/"..path)end
local function fixture(rawWidth,rawHeight,convertCode)
    local db={}
    local e=setmetatable({},{__index=_G});e._G=e
    e.Enum={EditModeSystem={UnitFrame=1},EditModeUnitFrameSystemIndices={Raid=2},EditModeUnitFrameSetting={FrameWidth=3,FrameHeight=4}}
    e.min,e.max,e.Clamp=math.min,math.max,function(x,a,b)return math.max(a,math.min(b,x))end
    local convert=assert(load(convertCode.."\nreturn ConvertValueDiffFromMin","@pinned-native-width-conversion","t",e))()
    local display={
        [3]={minValue=72,maxValue=144,ClampValue=function(self,x)return e.Clamp(x,self.minValue,self.maxValue)end},
        [4]={minValue=36,maxValue=72,ClampValue=function(self,x)return e.Clamp(x,self.minValue,self.maxValue)end}}
    for _,info in pairs(display)do info.ConvertValueForDisplay=function(self,x)return convert(self,x,true)end end
    e.EditModeSettingDisplayInfoManager={GetSystemSettingDisplayInfoMap=function(_,system)assert(system==1);return display end}
    e.EditModePresetLayoutManager={GetDefaultSettingForSystem=function(_,system,index,setting)
        assert(system==1 and index==2,"default resolution must use native raid defaults")
        return setting==3 and rawWidth or rawHeight
    end}
    e.EditModeManagerFrame=setmetatable({},{__index=function()error("candidate inspected an active native profile")end})
    e.FluxOptions={GetRaidFrameDB=function()return db end}
    e.GameFontHighlightSmall={GetFont=function()return "NativeSmall",10,""end}
    e.GameFontDisable={GetFont=function()return "NativeStatus",12,""end}
    e.GameFontNormalSmall={GetFont=function()return "LocalizedDuration",11,"NATIVE"end}
    e.CreateFrame=function(_,_,parent)return widget(parent)end
    e.UIParent=widget()
    assert(load(code,"@actual-raid-visuals","t",e))("_FluxUI",{Flux={}})
    return e.FluxRaidVisuals,e,db
end
local function nativeFrame(client,w,h)
    local text=source(client,"Blizzard_UnitFrame/Shared/CompactUnitFrame.lua")
    local setup=assert(text:match("function DefaultCompactUnitFrameSetup%b().-\nend"))
    local e=setmetatable({},{__index=function(_,key)
        if _G[key]~=nil then return _G[key]end
        return function()end
    end})
    e.min=math.min;e.DefaultCompactUnitFrameOptions={};e.DefaultCompactUnitFrameSetupOptions={}
    e.NATIVE_UNIT_FRAME_WIDTH,e.NATIVE_UNIT_FRAME_HEIGHT,e.NATIVE_UNIT_FRAME_AURA_SIZE=72,36,11
    e.NATIVE_UNIT_FRAME_CENTER_STATUS_ICON_SIZE=22
    local color={GetRGBA=function()return 1,1,1,1 end}
    e.CUF_MY_HEAL_PREDICTION_COLOR,e.CUF_OTHER_HEAL_PREDICTION_COLOR=color,color
    e.TextureKitConstants={};e.UnitGroupRolesAssigned=function()return"HEALER"end
    e.EditModeManagerFrame={GetRaidFrameWidth=function()return w end,GetRaidFrameHeight=function()return h end,
        ShouldRaidFrameDisplayBorder=function()return false end,GetRaidFrameAuraOrganizationType=function()return 0 end}
    e.CompactUnitFrame_GetOptionDisplayPowerBar=function()return true end
    e.CompactUnitFrame_GetOptionDisplayOnlyHealerPowerBars=function()return false end
    e.CompactUnitFrame_GetIconScale=function()return 1 end
    e.CompactUnitFrame_GetBuffIconScale=e.CompactUnitFrame_GetIconScale
    e.CompactUnitFrame_GetDebuffIconScale=e.CompactUnitFrame_GetIconScale
    e.CompactUnitFrame_GetBigDefensiveIconScale=e.CompactUnitFrame_GetIconScale
    e.CompactUnitFrame_IsPvpFrame=function()return false end
    local f=cell()
    assert(load(setup,"@pinned-native-default-setup-"..client,"t",e))()
    e.DefaultCompactUnitFrameSetup(f)
    return f
end

for _,client in ipairs({"live","forever","classic","classic_era","classic_anniversary"})do
    local settings=source(client,"Blizzard_EditMode/Shared/EditModeSettingDisplayInfo.lua")
    local convert=assert(settings:match("local function ConvertValueDiffFromMin%b().-\nend"))
    local family=(client=="live"or client=="forever")and"Mainline"or"Classic"
    local presets=source(client,"Blizzard_EditMode/"..family.."/EditModePresetLayouts.lua")
    local raid=assert(presets:match("%[Enum%.EditModeUnitFrameSystemIndices%.Raid%]%s*=%s*{%s*settings%s*=%s*{(.-)}"))
    local rawWidth=assert(tonumber(raid:match("%[Enum%.EditModeUnitFrameSetting%.FrameWidth%]%s*=%s*(%d+)")))
    local rawHeight=assert(tonumber(raid:match("%[Enum%.EditModeUnitFrameSetting%.FrameHeight%]%s*=%s*(%d+)")))
    local visual,e,db=fixture(rawWidth,rawHeight,convert)
    check(visual.GetBlizzardDefaultSizing().width==98,client..": native default metadata supplies the size baseline")
    local sizing=visual.GetBlizzardDefaultSizing()
    local native=nativeFrame(client,sizing.width,sizing.height)
    check(sizing.provenance=="native-default-preset"and native.width==98 and native.height==44,client..": native source preset and conversion produce98x44")
    check(visual.FRAME_WIDTH==native.width and visual.FRAME_HEIGHT==native.height,client..": startup matches the native default outer cell")
    local requested={memberWidthScale=.6,frameHeightScale=1.6,powerBarHeightScale=.5,auraIconScale=2.5}
    visual.ApplyRaidFrameTunables(requested)
    check(visual.FRAME_WIDTH==59 and visual.FRAME_HEIGHT==70 and visual.POWER_BAR_HEIGHT==4
        and requested.auraIconScale==2.5,client..": saved scales use native-relative dimensions without settings writes")
    visual.ApplyRaidFrameTunables({})
    check(near(visual.BLIZZARD_RAID_MANAGER_SCALE,.7),client..": manager slider1.00 uses the requested30percent smaller baseline")
    local frame=cell();visual.ApplyCellChrome(frame,{showPower=true})
    check(frame.healthBar.points[1][4]==native.healthBar.points[1][4]and frame.healthBar.points[1][5]==native.healthBar.points[1][5]
        and frame.healthBar.points[2][4]==native.healthBar.points[2][4]and frame.healthBar.points[2][5]==native.healthBar.points[2][5],
        client..": health has identical one-pixel insets and native power reservation")
    check(frame.powerBar.height==8 and not frame._fluxPowerDivider.shown,client..": native eight-pixel power strip has no extra divider row")
    check(near(frame.readyCheckIcon.width,native.readyCheckIcon.width)and near(frame.centerStatusIcon.width,native.centerStatusIcon.width),
        client..": center and ready status sizes follow the exact native component equation")
    check(frame.roleIcon.width==17 and near(frame.statusText.fontHeight,native.statusText.fontHeight)
        and frame.name.fontObject==e.GameFontHighlightSmall and frame.statusText.fontObject==e.GameFontDisable,
        client..": role and localized native font inheritance remain distinct")
    frame.statusText:SetTextScale(1.75)
    for refresh=1,50 do
        visual.ApplyCellChrome(frame,{showPower=true})
        check(near(frame.statusText.fontHeight,native.statusText.fontHeight)and frame.statusText.textScale==1,
            client..": repeated status refresh reads the Font baseline and resets local text scaling")
    end
    e.GameFontDisable.GetFont=function()return "LocalizedStatus",15,"LOCALIZED"end
    visual.ApplyCellChrome(frame,{showPower=true})
    check(frame.statusText.font[1]=="LocalizedStatus"and frame.statusText.font[3]=="LOCALIZED"
        and near(frame.statusText.fontHeight,15*sizing.componentScale),
        client..": native locale font file, flags and absolute base height are preserved")
    e.GameFontDisable.GetFont=function()return "NativeStatus",12,""end
    visual.ApplyRaidFrameTunables({memberWidthScale=1.1,frameHeightScale=1.5})
    local changedComponent=math.min(66/36,108/72)
    for refresh=1,50 do
        visual.ApplyCellChrome(frame,{showPower=true})
        check(near(frame.statusText.fontHeight,12*changedComponent)and frame.statusText.textScale==1,
            client..": changing frame scale applies the new absolute status height without double multiplication")
    end
    visual.ApplyRaidFrameTunables({})
    check(sizing.miniHeight==22 and visual.MINI_FRAME_HEIGHT==22 and visual.CELL_JOIN_OVERLAP==1,client..": mini height and shared edge use native dimensions")
    for buffs=1,6 do for debuffs=1,6 do
        local layout=visual.GetAuraLayout(nil,nil,{maxBuffs=buffs,maxDebuffs=debuffs,auraIconScale=1})
        check(layout.nativeDefaults and layout.width==11 and layout.height==11 and layout.scale==1
            and layout.buffs.slotWidth==11 and layout.debuffs.slotWidth==11,client..": native icon and large-slot sizes resist custom scaling")
        check(layout.buffs.blockWidth+layout.debuffs.blockWidth+layout.centerGutter<=layout.availableWidth
            and math.max(layout.buffs.blockHeight,layout.debuffs.blockHeight)<=layout.availableHeight,
            client..": native six-slot blocks fit within the native health rectangle")
    end end
    check(visual.GetAuraScaleLimit()==2.5,client..": native baseline permits explicit enlargement up to2.5")
    local font,size,flags=visual.GetAuraDurationFont(true)
    check(font=="LocalizedDuration"and size==11 and flags=="NATIVE",client..": visible duration uses the actual localized native font metadata")
    check(visual.GetAuraDurationFontSize(12,false)==11,client..": every caller uses the same localized native duration base")
    local saved={memberWidthScale=1.1,frameHeightScale=1.3,powerBarHeightScale=2,auraIconScale=.5}
    local pendingCustom=visual.GetAuraLayout(nil,nil,saved)
    visual.ApplyRaidFrameTunables(saved)
    check(visual.FRAME_WIDTH==108 and visual.FRAME_HEIGHT==57 and visual.POWER_BAR_HEIGHT==16 and visual.CELL_JOIN_OVERLAP==1
        and visual.MINI_FRAME_HEIGHT==28.5 and saved.auraIconScale==.5,client..": all existing scales multiply the native baseline without hidden modifiers or saved writes")
    local custom=visual.GetAuraLayout(nil,nil,saved)
    check(custom.nativeDefaults and near(custom.requestedHeight,5.5)and custom.buffs.slotWidth==custom.buffs.width,
        client..": existing aura requests now use the same square native-relative baseline")
    check(custom.availableHeight==pendingCustom.availableHeight and custom.scale==pendingCustom.scale,
        client..": pending custom bounds do not borrow native padding from the last applied scope")
    visual.ApplyCellChrome(frame,{showPower=true})
    check(frame.healthBar.points[2][4]==-1 and frame.healthBar.points[2][5]==17 and frame.readyCheckIcon.width==30,
        client..": actual scaled cells keep native insets and scale components using the native equation")
    visual.ApplyRaidFrameTunables({})
    visual.ApplyCellChrome(frame,{showPower=false})
    check(frame.healthBar.points[2][4]==-1 and frame.healthBar.points[2][5]==1 and not frame.powerBar.shown,
        client..": re-enabling native mode reclaims power space without old bottom padding")
    check(saved.frameHeightScale==1.3 and saved.memberWidthScale==1.1,client..": existing saved fields are retained without an automatic reset")
    if family=="Mainline"then
        local smaller=fixture(0,0,convert)
        local nativeSmall=nativeFrame(client,72,36)
        check(smaller.FRAME_WIDTH==nativeSmall.width and smaller.FRAME_HEIGHT==nativeSmall.height
            and smaller.GetBlizzardDefaultSizing().miniHeight==18,client..": native Classic default preset resolves72x36 instead of assuming Modern")
        local smallAuras=smaller.GetAuraLayout()
        check(smallAuras.width==11 and smallAuras.largeIconSize==16.5 and not smallAuras.overlap and smallAuras.physicalFitScale>1
            and smaller.GetAuraScaleLimit()==2.5,client..": stock1.00 remains exact when the Classic preset cannot contain all configured slots")
    end
    e.EditModePresetLayoutManager=nil;e.EditModeSettingDisplayInfoManager=nil
    check(visual.GetBlizzardDefaultSizing().provenance=="modern-source-fallback"and visual.GetBlizzardDefaultSizing().width==98,
        client..": unavailable native default metadata has an explicit source fallback")
end

local original=code
local settings=source("forever","Blizzard_EditMode/Shared/EditModeSettingDisplayInfo.lua")
local convert=assert(settings:match("local function ConvertValueDiffFromMin%b().-\nend"))
local expected=nativeFrame("forever",98,44)
local function contract()
    local v=fixture(26,8,convert)
    assert(v.GetBlizzardDefaultSizing().provenance=="native-default-preset")
    v.ApplyRaidFrameTunables({})
    assert(v.FRAME_WIDTH==expected.width and v.FRAME_HEIGHT==expected.height and v.POWER_BAR_HEIGHT==expected.powerBarUsedHeight)
    local f=cell();v.ApplyCellChrome(f,{showPower=true})
    assert(f.healthBar.points[2][4]==expected.healthBar.points[2][4]and f.healthBar.points[2][5]==expected.healthBar.points[2][5])
    assert(near(f.readyCheckIcon.width,expected.readyCheckIcon.width)and near(f.statusText.fontHeight,expected.statusText.fontHeight))
    for _=1,50 do v.ApplyCellChrome(f,{showPower=true})end
    assert(near(f.statusText.fontHeight,expected.statusText.fontHeight))
end
for _,mutant in ipairs({
    {"default baseline",'local hScale = tonumber%(opts.frameHeightScale%) or 1\n','local hScale = tonumber(opts.frameHeightScale) or 1.2\n'},
    {"power strip",'local POWER_BAR_HEIGHT_BASE = 8','local POWER_BAR_HEIGHT_BASE = 5'},
    {"health inset",'local rightInset = %-inset','local rightInset = 0'},
    {"component scale",'FluxRaidVisuals.COMPONENT_SCALE = min%(FluxRaidVisuals.FRAME_HEIGHT / NATIVE_UNIT_FRAME_HEIGHT,%s*FluxRaidVisuals.FRAME_WIDTH / NATIVE_UNIT_FRAME_WIDTH%)','FluxRaidVisuals.COMPONENT_SCALE = 1'},
    {"default profile ownership",'manager:GetDefaultSettingForSystem%(system, index, setting%)','EditModeManagerFrame:GetSettingValue(system,index,setting)'},
    {"status font baseline",'statusFont:GetFont%(%)','frame.statusText:GetFont()'},
})do
    local changed,n=original:gsub(mutant[2],mutant[3])
    check(n>0,"negative control targets "..mutant[1])
    code=changed
    check(not pcall(contract),"negative control rejects "..mutant[1])
end
code=original
print("Blizzard default raid sizes: "..checks.." checks; five pinned native setup/preset/conversion sources, absolute localized status fonts and scales; six rejected mutants; native rendering pending")
