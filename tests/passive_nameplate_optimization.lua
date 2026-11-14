-- Read-only actual-module replay; native widgets/APIs are counted stubs.
-- Execute from FluxUI repository. Does not load game or modify addon source.
local base = arg[1] or '.'
local output = arg[2]
local measure = arg[3] == '--measure'
local full = arg[4] == '--full'
local seconds = full and 60 or 2
local checks = 0
local function check(v,why) checks=checks+1;assert(v,why) end
local scenarios = {}
local sourcePaths = {'NamePlates/Core.lua','NamePlates/Level.lua','NamePlates/Threat.lua','NamePlates/Countdown.lua'}
local function run(branch, count, fps, topology, churn)
    local calls, objects, native, now = {}, {}, {}, 0
    local function hit(name) calls[name] = (calls[name] or 0) + 1 end
    local function widget(parent, kind)
        local w = {parent=parent,shown=true,alpha=1,width=100,height=12,level=10,points={},children={},kind=kind or 'Frame'}
        objects[#objects+1]=w
        if parent then parent.children[#parent.children+1]=w end
        function w:GetParent() return self.parent end
        function w:SetParent(p) hit('SetParent');self.parent=p end
        function w:Hide() hit('Hide');self.shown=false end
        function w:Show() hit('Show');self.shown=true end
        function w:SetShown(v) if v then self:Show() else self:Hide() end end
        function w:IsShown() hit('IsShown');return self.shown end
        function w:IsVisible() return self.shown end
        function w:SetSize(x,y) hit('SetSize');self.width,self.height=x,y end
        function w:GetWidth() hit('GetWidth');return self.width end
        function w:SetPoint(p,r,rp,x,y) hit('SetPoint');self.points[p]={p,r,rp,x or 0,y or 0} end
        function w:ClearAllPoints() hit('ClearAllPoints');self.points={} end
        function w:GetNumPoints() hit('GetNumPoints');local n=0;for _ in pairs(self.points) do n=n+1 end;return n end
        function w:GetPoint(i) hit('GetPoint');if self.pointError then error('unavailable point') end;local n=0;for _,p in pairs(self.points) do n=n+1;if n==i then return table.unpack(p) end end end
        function w:SetFrameLevel(v) hit('SetFrameLevel');self.level=v end
        function w:GetFrameLevel() hit('GetFrameLevel');return self.level end
        function w:GetAlpha() hit('GetAlpha');return self.alpha end
        function w:SetAlpha(v) hit('SetAlpha');self.alpha=v end
        function w:SetFont(...) hit('SetFont');self.font={...} end
        function w:GetStringWidth() hit('GetStringWidth');return #(self.text or '')*6 end
        function w:SetText(v) hit('SetText');self.text=v end
        function w:GetText() hit('GetText');return self.text end
        function w:SetFormattedText(f,...) self:SetText(string.format(f,...)) end
        function w:SetTextColor() hit('SetTextColor') end
        function w:SetVertexColor() hit('SetVertexColor') end
        function w:SetTexture() hit('SetTexture') end
        function w:SetTexCoord() end
        function w:SetAtlas() end
        function w:SetTextureSliceMargins() end
        function w:EnableMouse() end
        function w:SetShadowColor() end
        function w:SetShadowOffset() end
        function w:SetJustifyH() end
        function w:SetJustifyV() end
        function w:SetWordWrap() end
        function w:SetTextHeight() hit('SetTextHeight') end
        function w:CreateTexture() hit('CreateTexture');return widget(self,'Texture') end
        function w:CreateFontString() hit('CreateFontString');return widget(self,'FontString') end
        function w:GetObjectType() return self.kind end
        function w:SetScript(s,f) self.scripts=self.scripts or {};self.scripts[s]=f end
        function w:HookScript(s,f) self.hooks=self.hooks or {};self.hooks[s]=self.hooks[s] or {};table.insert(self.hooks[s],f) end
        function w:RegisterEvent(e) self.events=self.events or {};self.events[e]=true end
        function w:GetChildren() hit('GetChildren');return table.unpack(self.children) end
        function w:IsTarget() return false end
        function w:IsFocus() return false end
        return w
    end
    local ui=widget()
    local Flux={Client={isRetail=branch=='retail',isLiveMidnight=branch=='retail',isForever=branch=='forever',isCamelot=branch=='forever',majorVersion=branch=='retail' and 12 or 1}}
    Flux.Threat={IsVisibilityAllowed=function() return true end,IsNameplateThreatTarget=function() return true end,GetNumericDisplay=function() hit('ThreatDisplay');return 50,1,false end,
      GetForeverFrameDisplay=function() hit('ThreatDisplay');return 50,1,false end,ShouldShowThreat=function() return true end,
      GetPlayerRank=function() return 2 end,GetTintColor=function() return 1,1,0 end,
      SetRankPercentText=function(t,r,p) t:SetText('2 50%') end}
    local env=setmetatable({UIParent=ui,FluxUI_DB={nameplateThreat={questOverlayEnabled=false,visibilityMode='always'}},
      WOW_PROJECT_MAINLINE=1,WOW_PROJECT_ID=1,GetTime=function() return now end,
      SettingsPanel={IsShown=function() hit('SettingsIsShown');return false end},
      UnitLevel=function() hit('UnitLevel');return 70 end,UnitClassification=function() return 'normal' end,
      UnitCanAttack=function() return true end,UnitExists=function() return true end,UnitIsPlayer=function() return false end,
      UnitAffectingCombat=function() return true end,UnitIsUnit=function() return false end,
      NamePlateSetupOptions={levelFontHeight=10},issecretvalue=function() return false end,
      IsInGroup=function() return true end,IsInRaid=function() return false end,
      GetRelativeDifficultyColor=function() return {r=1,g=1,b=0} end,
      geterrorhandler=function() return function(err) error(err) end end,
      wipe=function(t) for k in pairs(t) do t[k]=nil end end,
    },{__index=_G});env._G=env
    env.CreateFrame=function(_,_,p) hit('CreateFrame');return widget(p) end
    env.C_NamePlate={GetNamePlateForUnit=function(unit) hit('GetNamePlateForUnit');return native[unit] end,GetNamePlates=function() return {} end}
    for i=1,count do
        local plate=widget(ui);plate.unitToken='nameplate'..i
        local uf=widget(plate);uf.unit=plate.unitToken;plate.UnitFrame=uf
        uf.HealthBarsContainer=widget(uf);local h=uf.HealthBarsContainer;h.healthBar=widget(h)
        h.healthBar.bgTexture=widget(h.healthBar);h.border=widget(h);h.healthBar.selectedBorder=widget(h.healthBar)
        uf.CastBarsContainer=widget(uf);uf.LevelFrame=widget(uf)
        uf.LevelFrame.LevelText=widget(uf.LevelFrame,'FontString');uf.LevelFrame.HighLevelTexture=widget(uf.LevelFrame,'Texture')
        uf.PlayerLevelDiffFrame=widget(uf)
        for _,key in ipairs({'playerLevelDiffText','playerLevelDiffIcon','highLevelTexture','selectedBorder'}) do uf.PlayerLevelDiffFrame[key]=widget(uf.PlayerLevelDiffFrame) end
        uf.AurasFrame=widget(uf);local a=uf.AurasFrame
        a.DebuffListFrame=widget(a);a.BuffListFrame=widget(a);a.CrowdControlListFrame=widget(a)
        local auraItems={}
        for j=1,4 do
            local item=widget(topology=='pool+list' and a.DebuffListFrame or a)
            item.Cooldown=widget(item);local cd=item.Cooldown;local digits=widget(cd,'FontString');digits.text='30'
            function cd:GetCountdownFontString() hit('GetCountdownFontString');return digits end
            auraItems[j]=item
        end
        a.auraItemFramePool={EnumerateActive=function() local j=0;return function() j=j+1;if auraItems[j] then return auraItems[j],true end end end}
        native[plate.unitToken]=plate
    end
    local ns={Flux=Flux}
    for _,p in ipairs(sourcePaths) do assert(loadfile(base..'/'..p,'t',env))('_FluxUI',ns) end
    local eventFrame,driver
    for _,w in ipairs(objects) do
        if w.events and w.events.NAME_PLATE_UNIT_ADDED then eventFrame=w end
        if w.scripts and w.scripts.OnUpdate then driver=w end
    end
    assert(eventFrame and driver,'actual Core driver/event frame found')
    local function event(name,unit) eventFrame.scripts.OnEvent(eventFrame,name,unit) end
    local row={branch=branch,plates=count,fps=fps,seconds=seconds,topology=topology,mode=churn and '1000-add-remove-cycles' or 'steady',stub_limitations='plain values; native widget costs not timed; four unchanging aura labels per plate; quest overlay disabled; threat always visible'}
    if churn then
        calls={};local before=#objects
        for _=1,1000 do event('NAME_PLATE_UNIT_ADDED','nameplate1');event('NAME_PLATE_UNIT_REMOVED','nameplate1') end
        row.objects_created=#objects-before
        row.frames_created=calls.CreateFrame or 0
        row.visible_units=next(Flux.NamePlates.activeUnits)==nil and 0 or 1
        if not measure then check(row.frames_created <= 8,'overlay lifecycle allocations must be bounded') end
        row.note='Retained stub objects model native widgets; frame persistence is a native contract, not measured memory bytes.'
    else
        for i=1,count do event('NAME_PLATE_UNIT_ADDED','nameplate'..i) end
        -- Settle periodic state, then count the next sixty simulated seconds.
        for i=1,fps do now=i/fps;driver.scripts.OnUpdate(driver,1/fps);for _,fn in ipairs(driver.hooks and driver.hooks.OnUpdate or {}) do fn(driver,1/fps) end end
        calls={}
        for i=1,seconds*fps do now=1+i/fps;driver.scripts.OnUpdate(driver,1/fps);for _,fn in ipairs(driver.hooks and driver.hooks.OnUpdate or {}) do fn(driver,1/fps) end end
    end
    row.calls=calls
    if not churn then
        if not measure then
            check((calls.GetNamePlateForUnit or 0)<=count,'settled lookup cache budget')
            check((calls.SetFont or 0)==0,'stable font budget')
            check((calls.SetPoint or 0)==0,'stable owned anchor budget')
        end
        row.behavior={}
        local function paint()
            driver.scripts.OnUpdate(driver,1/fps)
            for _,fn in ipairs(driver.hooks and driver.hooks.OnUpdate or {}) do fn(driver,1/fps) end
        end
        local plate=native.nameplate1;local uf=plate.UnitFrame
        if branch=='forever' then
            local health=uf.HealthBarsContainer
            for _,r in ipairs({uf.LevelFrame.LevelText,uf.LevelFrame.HighLevelTexture,
                uf.PlayerLevelDiffFrame.playerLevelDiffText,uf.PlayerLevelDiffFrame.playerLevelDiffIcon,
                uf.PlayerLevelDiffFrame.highLevelTexture,uf.PlayerLevelDiffFrame.selectedBorder}) do r.alpha=1 end
            health.points.BOTTOMRIGHT={'BOTTOMRIGHT',uf.CastBarsContainer,'TOPRIGHT',13,99}
            health.points.TOPLEFT={'TOPLEFT',plate,'TOPLEFT',0,0}
            paint()
            check(uf.LevelFrame.LevelText.alpha==0,'native alpha reset repaired next frame')
            check(health.points.BOTTOMRIGHT[4]==0 and health.points.BOTTOMRIGHT[5]==2,'native anchor reset repaired next frame')
            -- Failed getters keep repair behavior, even after an index was cached.
            health.pointError=true;health.points.BOTTOMRIGHT[4]=45;paint()
            check(health.points.BOTTOMRIGHT[4]==0,'failed getter repairs rather than trusts cached native geometry')
            health.pointError=false
            uf.LevelFrame.LevelText=widget(uf.LevelFrame,'FontString');paint()
            check(uf.LevelFrame.LevelText.alpha==0,'replacement native region fades next frame')
            row.behavior={alpha=uf.LevelFrame.LevelText.alpha,healthX=health.points.BOTTOMRIGHT[4],healthY=health.points.BOTTOMRIGHT[5]}
        else
            uf.LevelFrame.shown=true;uf.PlayerLevelDiffFrame.shown=true;paint()
            check(not uf.LevelFrame.shown and not uf.PlayerLevelDiffFrame.shown,'native visibility reset repaired next frame')
            row.behavior={levelShown=uf.LevelFrame.shown,diffShown=uf.PlayerLevelDiffFrame.shown}
        end
        -- Same-token repeated ADD + explicit style refresh must reconcile a new plate.
        local replacement=widget(ui);replacement.unitToken='nameplate1';replacement.UnitFrame=uf
        native.nameplate1=replacement
        event('NAME_PLATE_UNIT_ADDED','nameplate1');Flux.NamePlates.RefreshAll()
        check(Flux.NamePlates.GetPlate('nameplate1')==replacement,'same-token replacement reconciled')
        event('NAME_PLATE_UNIT_REMOVED','nameplate1')
        check(not Flux.NamePlates.activeUnits.nameplate1,'removal clears roster')
    end
    scenarios[#scenarios+1]=row
end
for _,branch in ipairs({'retail','forever'}) do
    if full then
        for _,count in ipairs({1,20,40}) do
            for _,fps in ipairs({60,144,240}) do run(branch,count,fps,'pool-only',false) end
        end
    else run(branch,20,144,'pool-only',false) end
    run(branch,20,144,'pool+list',false)
    run(branch,1,60,'pool-only',true)
end
local function json(v)
    if type(v)=='string' then return '"'..v:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n')..'"' end
    if type(v)=='number' or type(v)=='boolean' then return tostring(v) end
    local array=true;local n=0;for k in pairs(v) do n=n+1;if type(k)~='number' then array=false end end
    local out={};if array then for i=1,n do out[#out+1]=json(v[i]) end;return '['..table.concat(out,',')..']' end
    local keys={};for k in pairs(v) do keys[#keys+1]=k end;table.sort(keys)
    for _,k in ipairs(keys) do out[#out+1]=json(k)..':'..json(v[k]) end
    return '{'..table.concat(out,',')..'}'
end
local result=json({scope='actual unchanged NamePlates Core/Level/Threat/Countdown operation replay',lua=_VERSION,source_paths=sourcePaths,scenarios=scenarios})
if output then local f=assert(io.open(output,'wb'));f:write(result,'\n');f:close() else print(result) end
print('PASS: '..#scenarios..' actual-module scenarios; '..checks..' checks; no native FPS or CPU measurement')
