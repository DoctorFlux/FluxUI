-- Exercise metric failure/recovery through the unchanged full-module fixture.
local f=assert(io.open('tests/passive_nameplate_optimization.lua','rb'));local source=f:read('*a');f:close()
local marker='        -- Same-token repeated ADD + explicit style refresh must reconcile a new plate.'
local at=assert(source:find(marker,1,true))
local probe=[[
        local levelLabel,threatLabel
        for _,host in ipairs(objects) do if host.parent==plate then
            for _,child in ipairs(host.children or {}) do
                if child.kind=='FontString' and child.text=='Lvl. 70' then levelLabel=child end
                if child.kind=='FontString' and child.text=='2 50%' then threatLabel=child end
            end
        end end
        local function quarter()
            driver.scripts.OnUpdate(driver,0.25)
            for _,fn in ipairs(driver.hooks and driver.hooks.OnUpdate or {}) do fn(driver,0.25) end
        end
        if branch=='forever' then
            check(levelLabel~=nil,'level label exists')
            local get=levelLabel.GetStringWidth
            levelLabel.GetStringWidth=function() error('font metrics temporarily unavailable') end
            env.NamePlateSetupOptions.levelFontHeight=13
            Flux.NamePlates.RefreshAll()
            check(levelLabel.parent.width==52,'failed level metrics use original default width')
            levelLabel.GetStringWidth=function(self) return get(self)+17 end;quarter()
            check(levelLabel.parent.width==get(levelLabel)+27,'level metrics recover next original poll')
        end
        check(threatLabel~=nil,'threat label exists')
        local get=threatLabel.GetStringWidth;local rank=Flux.Threat.GetPlayerRank
        threatLabel.GetStringWidth=function() error('font metrics temporarily unavailable') end
        Flux.Threat.GetPlayerRank=function() return 3 end;quarter()
        check(threatLabel.parent.width==54,'failed threat metrics use original default width')
        threatLabel.GetStringWidth=get;quarter()
        check(threatLabel.parent.width==#threatLabel.text*6+4,'threat metrics recover without another value change')
        Flux.Threat.GetPlayerRank=rank

        if branch=='forever' then
            local health=uf.HealthBarsContainer
            local countGetter=health.GetNumPoints
            health.GetNumPoints=function() error('count temporarily unavailable') end
            health.points.BOTTOMRIGHT[4]=37;quarter()
            check(health.points.BOTTOMRIGHT[4]==0,'failed point-count getter preserves same-poll repair')
            local opaque={};local secretGetter=env.issecretvalue
            env.issecretvalue=function(v) return v==opaque end
            health.GetNumPoints=function() return opaque end
            health.points.BOTTOMRIGHT[4]=38;quarter()
            check(health.points.BOTTOMRIGHT[4]==0,'secret point-count getter preserves same-poll repair')
            health.GetNumPoints=countGetter;env.issecretvalue=secretGetter
            local pointGetter=health.GetPoint
            local mode='public'
            health.GetNumPoints=function() return 2 end
            health.GetPoint=function(_,index)
                if index==1 then
                    if mode=='secret' then return opaque,plate,'TOPLEFT',0,0 end
                    if mode=='mismatch' then return 'BOTTOMRIGHT',uf.CastBarsContainer,'TOPRIGHT',9,2 end
                    return 'TOPLEFT',plate,'TOPLEFT',0,0
                end
                return 'BOTTOMRIGHT',uf.CastBarsContainer,'TOPRIGHT',0,2
            end
            quarter() -- A matching requested anchor occupies index two.
            env.issecretvalue=function(v) return v==opaque end
            local writes=calls.SetPoint or 0;mode='secret';quarter()
            check((calls.SetPoint or 0)>writes,'secret preceding point cannot be bypassed by an index hint')
            writes=calls.SetPoint or 0;mode='mismatch';quarter()
            check((calls.SetPoint or 0)>writes,'earlier mismatching requested point retains original repair/order')
            health.GetNumPoints=countGetter;health.GetPoint=pointGetter;env.issecretvalue=secretGetter
        end
        local settingsGetter=env.SettingsPanel.IsShown
        env.SettingsPanel.IsShown=function() return true end
        if branch=='forever' then uf.LevelFrame.LevelText.alpha=1 else uf.LevelFrame.shown=true end
        quarter()
        check(branch=='forever' and uf.LevelFrame.LevelText.alpha==1 or branch=='retail' and uf.LevelFrame.shown,
            'settings-open native preview/reset context remains untouched')
        env.SettingsPanel.IsShown=settingsGetter;quarter()
        check(branch=='forever' and uf.LevelFrame.LevelText.alpha==0 or branch=='retail' and not uf.LevelFrame.shown,
            'settings-close resumes next-frame native repair')
        local countdownHost
        for _,host in ipairs(objects) do
            if host.parent==plate and host.text and host.text.text=='30' then countdownHost=host;break end
        end
        check(countdownHost~=nil,'countdown host exists for reparent recovery')
        local setParent=countdownHost.SetParent
        countdownHost.SetParent=function(self,parent) setParent(self,parent);self.level=1 end
        countdownHost.parent=nil;quarter()
        check(countdownHost.level==15,'same-number new parent invalidates inherited countdown level')
        countdownHost.SetParent=setParent
        local removedLookup=false
        Flux.NamePlates.RegisterModule('removed-lookup-probe',{Removed=function(unit)
            if unit=='nameplate1' then removedLookup=Flux.NamePlates.GetPlate(unit) end
        end})
        native.nameplate1=nil;event('NAME_PLATE_UNIT_REMOVED','nameplate1')
        check(removedLookup==nil,'removed callback observes fresh native nil rather than stale cached plate')
        native.nameplate1=plate;event('NAME_PLATE_UNIT_ADDED','nameplate1')
]]
source=source:sub(1,at-1)..probe..source:sub(at)
-- Keep this extra fixture quiet; the ordinary replay produces the machine results.
source=source:gsub('else print%(result%) end','end',1)
assert(load(source,'@nameplate-metric-recovery'))()
