-- Actual FluxBorder and grid controller with strict protected-write guards.
-- Native texture rendering, input dispatch/taint and FPS remain unverified.
local function read(path)
    local f=assert(io.open(path,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s
end
local source=read(os.getenv('FLUX_MINIMAP_EXTRA_SOURCE') or 'Minimap/FluxMinimapButtons.lua')
local borderSource=read('FluxBorder.lua')
local arrowSource=read('ExtraButtonSystem/FlyoutEngine/Arrow.lua')
local fixture=read('tests/minimap_extra_layout.lua')
fixture=fixture:sub(1,assert(fixture:find('local function physical(frame)',1,true))-1)
fixture=fixture:gsub('local source = read[^\n]*','local source = ...',1)
local checks=0
local function check(ok,why) checks=checks+1;assert(ok,why) end
local function near(a,b,why) check(math.abs(a-b)<.001,why) end
local tiers={BACKGROUND=1,LOW=2,MEDIUM=3,HIGH=4,DIALOG=5,FULLSCREEN=6,FULLSCREEN_DIALOG=7,TOOLTIP=8}
local function above(a,b)
    local x,y=tiers[a:GetFrameStrata()],tiers[b:GetFrameStrata()]
    return x>y or (x==y and a:GetFrameLevel()>b:GetFrameLevel())
end
local function model(src,client,atlas,scale)
    local boot=assert(load(fixture..'\nreturn boot','@strict side-border fixture','t',_G))(src)
    local t=boot(nil,function(t,e)
        local create=e.CreateFrame
        local function decorate(f,kind)
            function f:GetObjectType() return kind or 'Frame' end
            function f:SetTexture(v) self.texture=v end
            function f:SetTexCoord(...) self.coords={...} end
            function f:SetVertexColor(...) self.color={...} end
            function f:GetVertexColor() return table.unpack(self.color or {1,1,1,1}) end
            function f:SetColorTexture(...) self.fill={...} end
            function f:SetAtlas(name,useSize) self.atlas=name;if useSize then self:SetSize(16,17) end end
            function f:CreateTexture()
                local x=decorate(create('Frame',nil,self),'Texture');return x
            end
            return f
        end
        for _,f in ipairs(t.frames) do decorate(f) end
        e.CreateFrame=function(kind,...) return decorate(create(kind,...),kind) end
        e.UnitClass=function() return 'Mage','MAGE' end
        e.RAID_CLASS_COLORS={MAGE={r=.2,g=.7,b=.9}}
        e.C_Texture={GetAtlasInfo=function() if atlas then return {width=16,height=17} end end}
        e.Flux.Client={isForever=client=='forever'}
        e.FluxOptions={db={profile={appearance={borderAccent='custom',customAccent={r=.3,g=.5,b=.7}}}}}
        assert(load(borderSource,'@actual FluxBorder','t',e))('_FluxUI',{Flux=e.Flux})
        local widget=e.Flux.EBS.Widget.Create
        e.Flux.EBS.Widget.Create=function(...)
            local b=widget(...);b.Widget:SetFrameStrata('MEDIUM');return b
        end
        local flyout=e.Flux.EBS.Flyout
        local bound={}
        flyout.InLockdown=e.InCombatLockdown
        flyout.HostOf=function(w) return bound[w] end
        flyout.BindHost=function(w,opts) bound[w]={opts=opts} end
        local configure=assert(arrowSource:match('(function Arrow.ConfigureLayer.-)\nfunction Arrow.Rotation'))
        local configureLayer=assert(load([[local Flyout=...
local Arrow={}
local ARROW_STRATA,ARROW_FRAME_LEVEL,ARROW_ABOVE_BORDER_ART='MEDIUM',9,5
]]..configure..'\nreturn Arrow.ConfigureLayer','@actual arrow layers','t',e))(flyout)
        flyout.Arrow={Update=function(w)
            if w:GetName()~='FluxMinimapExtraButton1' then return end
            if not t.arrow then t.arrow=e.CreateFrame('Button',nil,w,'SecureActionButtonTemplate') end
            configureLayer(t.arrow,w)
        end}
        t.cluster=e.CreateFrame('Frame',nil,e.UIParent);t.cluster:SetFrameStrata('MEDIUM');t.cluster:SetFrameLevel(200)
        t.clock=e.CreateFrame('Button',nil,e.UIParent);t.clock:SetFrameStrata('MEDIUM');t.clock:SetFrameLevel(45)
        t.info=e.CreateFrame('Frame',nil,e.UIParent);t.info:SetFrameStrata('MEDIUM');t.info:SetFrameLevel(10)
    end)
    local m,e=t.api,t.env
    check(not e.FluxMinimapButtonsSideBorder and t.creates==0,'disabled side grid allocates no border or widgets')
    e.UIParent:SetScale(scale)
    m:SetSetting('sideEnabled',true)
    local host=assert(e.FluxMinimapButtonsSideBorder,'active side grid uses a real FluxBorder host')
    local gate=e.FluxMinimapButtonsVisibility
    local root=e.FluxMinimapButtonsContainer
    local border=assert(host.FluxBorderFrame,'shared FluxBorder builds its normal chrome')
    check(host:GetParent()==gate,'border is inside the same secure visibility gate as buttons')
    check(host:IsVisible() and border:IsVisible() and border.Background:IsVisible(),'normal side grid shows border and themed backdrop')
    check(not host.mouse and not border.mouse and not border.BackgroundFrame.mouse,'decorative border cannot consume button or clock clicks')
    check(host.allPoints==gate,'border follows the exact grid rectangle without extra layout spacing')
    for _,b in ipairs(t:visible()) do
        check(above(b.Widget,t.clock) and above(b.Widget,t.cluster) and above(b.Widget,t.info),'native-template buttons render and receive hits above minimap clock and cluster')
        check(above(border,b.Widget) and above(b.Widget,border.BackgroundFrame),'chrome surrounds buttons;backdrop sits below button art')
    end
    check(above(border.BackgroundFrame,t.clock),'side backdrop stays above map/clock instead of shared BACKGROUND tier')
    check(above(t.arrow,border),'existing flyout arrow stays above side border')
    check((border.TL.atlas~=nil)==atlas,'real FluxBorder chooses selected atlas/legacy art path')
    check(border.TL.color[1]==.3 and border.Background.fill[4]==.85,'border uses current shared theme and backdrop alpha')
    local frames=#t.frames
    for _,start in ipairs({'top','below'}) do
        m:SetSetting('sideStart',start)
        for _,percent in ipairs({10,100,200}) do
            m:SetSetting('sideScale',percent)
            near(border:GetEffectiveScale(),root:GetEffectiveScale(),'border scales with whole side grid')
            near(border.Background:GetEffectiveScale(),root:GetEffectiveScale(),'backdrop inherits whole-grid scale')
            check(e.FluxMinimapButtonsSideBorder==host and #t.frames==frames,'reflow and scale reuse decorative frame/texture resources')
        end
    end
    e.FluxOptions.db.profile.appearance.customAccent={r=.8,g=.4,b=.2}
    e.FluxBorder:RefreshAllAccentedFrames();m:RefreshAppearanceAccent()
    check(border.TL.color[1]==.8 and border.TL.color[3]==.2,'shared appearance refresh updates existing side border')
    check(e.FluxBorder._accentFrames[host],'host participates in the existing accent registry')
    m:SetSetting('hideInCombat',true)
    t:combatState(true)
    check(not host:IsVisible() and not border:IsVisible() and not border.Background:IsVisible() and #t:visible()==0,'secure combat hiding removes border background and buttons together')
    local writes=t.structuralWrites;m:UpdateSideBorder()
    check(t.structuralWrites==writes,'border refresh requests defer without insecure combat writes')
    t:combatState(false)
    check(host:IsVisible() and border.Background:IsVisible(),'combat exit restores border through shared visibility owner')
    m:SetSetting('hideInCombat',false);m:SetSetting('sideVisibility','mouseover')
    check(not host:IsVisible() and #t:visible()==0,'mouseover leaving area hides border and buttons together')
    local x,y,w,h=root:rect();t.cursorX,t.cursorY=x+w/2,y+h/2;t:tick()
    check(host:IsVisible() and #t:visible()==15,'hovering hidden grid reveals border with all buttons')
    t:combatState(true);writes=t.structuralWrites;t.cursorX,t.cursorY=0,0;t:tick()
    check(host:IsVisible() and #t:visible()==15 and t.structuralWrites==writes,'mouseover border freezes with shown buttons throughout combat')
    t:combatState(false)
    check(not host:IsVisible() and #t:visible()==0,'combat exit resumes mouseover hiding for both chrome and buttons')
    m:SetSetting('sideVisibility','always')
    t:embed(256)
    check(not host:IsVisible() and #t:visible()==15 and root:GetFrameStrata()=='MEDIUM','embedded grid removes side border and restores its original HUD layer')
    for _,b in ipairs(t:visible()) do check(b.Widget:GetFrameStrata()=='MEDIUM','embedded widgets restore inherited HUD layer after native-template override') end
    t:normal()
    check(host:IsVisible() and e.FluxMinimapButtonsSideBorder==host,'returning to side mode reuses same themed border')
    m:SetSetting('sideHideEmpty',true)
    check(not host:IsVisible() and #t:visible()==0,'all-empty grid hides its border instead of leaving an empty box')
    t.cursorType='spell';t:event('CURSOR_CHANGED');t:flush()
    check(host:IsVisible() and #t:visible()==1,'carried-action placeholder brings its border with it')
    t.cursorType=nil;t:event('CURSOR_CHANGED');t:flush()
    check(not host:IsVisible(),'cancelled empty placeholder hides border again')
    m:SetSetting('sideHideEmpty',false);m:SetSetting('sideEnabled',false)
    check(not host:IsVisible() and #t:visible()==0,'disabled grid leaves no detached border')
    return true
end
for _,client in ipairs({'retail','forever','classic','era','anniversary'}) do
    for _,atlas in ipairs({true,false}) do
        for _,scale in ipairs({.7,1,1.4}) do model(source,client,atlas,scale) end
    end
end
local function replace(s,old,new)
    local i=assert(s:find(old,1,true),old);return s:sub(1,i-1)..new..s:sub(i+#old)
end
local controls={
    {replace(source,'"FluxMinimapButtonsSideBorder", visibilityFrame','"FluxMinimapButtonsSideBorder", UIParent'),'border is inside the same secure visibility gate'},
    {replace(source,'layoutMode == "side" and "HIGH" or "MEDIUM"','"MEDIUM"'),'native-template buttons render and receive hits above minimap clock'},
    {replace(source,'widget:SetFrameStrata(strata)','-- template MEDIUM left unchanged'),'native-template buttons render and receive hits above minimap clock'},
    {replace(source,'background:SetFrameStrata("HIGH")','background:SetFrameStrata("BACKGROUND")'),'side backdrop stays above map/clock'},
    {replace(source,'    self:UpdateSideBorder()','    -- border omitted'),'active side grid uses a real FluxBorder host'},
    {replace(source,'if sideBorderHost then sideBorderHost:Hide() end','-- detached border left shown'),'embedded grid removes side border'},
    {replace(source,'elseif event == "PLAYER_REGEN_DISABLED" then','elseif event == "PLAYER_REGEN_DISABLED" then sideBorderHost:Hide()'),'no insecure combat mutation: Hide'},
}
for i,row in ipairs(controls) do
    local ok,err=pcall(model,row[1],'control',true,1)
    check(not ok and tostring(err):find(row[2],1,true),'harmful border control '..i..' must fail intended assertion: '..tostring(err))
end
print('Minimap side border: '..checks..' checks;actual FluxBorder/arrow layers;5 client models;30 art/scale cases;'..#controls..' harmful controls PASS')
