-- Real marker updaters; sentinel coordinates can only reach a native texture sink.
local function read(path)local f=assert(io.open(path,"rb"));local s=f:read("*a"):gsub("\r\n","\n");f:close();return s end
local function slice(s,a,b)local x=assert(s:find(a,1,true));local y=assert(s:find(b,x+#a,true));return s:sub(x,y-1)end
local checks=0
local function check(v,label)checks=checks+1;assert(v,label)end
local secret=setmetatable({},{__lt=function()error("private index comparison")end,__le=function()error("private index comparison")end,__sub=function()error("private UV arithmetic")end,__tostring=function()error("private index formatting")end})
local function opaque(v)return rawequal(v,secret)end
local shared=read("UnitFrames/FluxUnitFrames_Shared.lua")
local raid=read(os.getenv("FLUX_MARKER_RAID_SOURCE")or"RaidFrame/FluxRaidUnit.lua")
for _,client in ipairs({"live","forever","classic","classic_era","classic_anniversary"})do
    local index,enabled=nil,true
    local E=setmetatable({UF={},ValueIsSecret=opaque,IsSecret=opaque,UnitOf=function(f)return f.unit end,
        GetRaidTargetIndex=function()return index end,FluxUnitFrames_ShouldShowRaidIcon=function()return enabled end,
        ShowRegion=function(icon,v)if v then icon:Show()else icon:Hide()end end},{__index=_G})
    E.SetRaidTargetIconTexture=function(icon,v)check(not opaque(v),"legacy Lua helper never receives private index");icon.cell=v end
    assert(load(slice(shared,"function UF.UpdateRaidMarker", "function UF.UpdateOuterBorder"),"@marker-shared","t",E))()
    assert(load(slice(raid,"local function SetCenterTexture", "function FluxRaid_UpdateReadyCheck"),"@marker-raid","t",E))()
    local function texture(native)
        local t={Hide=function(s)s.shown=false end,Show=function(s)s.shown=true end,
            SetTexture=function(s,p)s.sheet=p end,SetSize=function(s,w,h)s.width,s.height=w,h end,
            ClearAllPoints=function()end,SetPoint=function(s,...)s.point={...}end}
        if native then t.SetSpriteSheetCell=function(s,v,rows,cols)s.cell=v;check(rows==4 and cols==4,"native sheet dimensions match Blizzard")end end
        return t
    end
    for _,unit in ipairs({"player","target","focus","party1","party4","raid1"})do
        for _,native in ipairs({true,false})do
            local icon=texture(native)
            local frame={unit=unit,raidIcon=icon,raidTargetIcon=icon,centerStatusIcon=texture(true),Health={GetHeight=function()return 40 end}}
            for marker=1,8 do
                index=marker
                E.FluxRaid_UpdateCenterStatus(frame)
                check(icon.shown and icon.cell==marker and icon.sheet=="Interface\\TargetingFrame\\UI-RaidTargetingIcons",client.." raid path sets sheet and cell for all eight marks")
                icon.cell=nil;E.UF.UpdateRaidMarker(frame)
                check(icon.shown and icon.cell==marker,"normal UF path draws all eight marks")
            end
            for _,none in ipairs({0,-1,9})do
                index=none;E.FluxRaid_UpdateCenterStatus(frame);check(not icon.shown,"invalid marker clears raid texture")
                E.UF.UpdateRaidMarker(frame);check(not icon.shown,"invalid marker clears unit texture")
            end
            index=nil;E.FluxRaid_UpdateCenterStatus(frame);check(not icon.shown,"raid removal clears stale marker")
            E.UF.UpdateRaidMarker(frame);check(not icon.shown,"unit removal clears stale marker")
            index=secret;E.FluxRaid_UpdateCenterStatus(frame)
            check(icon.shown==native,"raid restricted index renders only through native sprite sink")
            E.UF.UpdateRaidMarker(frame);check(icon.shown==native,"unit restricted index renders only through native sprite sink")
            if native then check(rawequal(icon.cell,secret),"private index forwarded unchanged")end
            index=8;enabled=false;E.UF.UpdateRaidMarker(frame);check(not icon.shown,"normal raid-marker option remains respected")
            enabled=true;E.UF.LayoutRaidMarker(frame)
            check(icon.width==36 and icon.point[1]=="CENTER"and icon.point[2]==frame.Health,"HP-centered player/party geometry retained")
        end
    end
end
print("Raid markers: "..checks.." checks; readable/restricted/all-eight/removal on five source-client models; native pixels/taint pending")
