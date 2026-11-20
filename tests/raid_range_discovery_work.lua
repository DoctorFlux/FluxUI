-- Actual range fallback owner: discovery may stop at one live cell; the
-- periodic painter must still visit every current owner. Native timing and
-- secure/render behavior are outside this desktop fixture.
local function read(path)
    local f=assert(io.open(path,"rb"));local s=f:read("*a"):gsub("\r\n","\n");f:close();return s
end
local source=read(os.getenv("FLUX_RANGE_DISCOVERY_SOURCE") or "RaidFrame/FluxRaidUnit.lua")
local first=source:find("-- Shared range helpers keep per-discovery state in arguments only.",1,true)
    or assert(source:find("EnsureRangePoll = function(frame)",1,true))
local last=assert(source:find("-- MT/MA target minis:",first,true))
local body=source:sub(first,last-1)
local needsPollName=body:find("if RangeFallbackNeedsPoll(btn) then",1,true) and "RangeFallbackNeedsPoll" or "NeedsPoll"
local checks=0
local measuring=os.getenv("FLUX_RANGE_DISCOVERY_MEASURE")=="1"
local function check(v,m) checks=checks+1;assert(v,m) end
local function improved(v,m) if not measuring then check(v,m) end end

local function fixture(text)
    local state={frameArray={},partyRangeFrames={}}
    local reads,paints,tickers=0,{},{}
    local e=setmetatable({State=state,enabled=true},{__index=_G});e._G=e
    -- Fix iteration order to exercise both the first-owner and late-owner
    -- cases without depending on Lua's table hash order.
    e.pairs=function(t)
        local index=0
        return function() index=index+1;if t[index] then return t[index],true end end
    end
    e.FluxRaid_IsFluxRaidEnabled=function() return e.enabled end
    e.FluxRaid_UpdateRange=function(f) paints[#paints+1]=f.id end
    e.C_Timer={NewTicker=function(interval,fn)
        local t={interval=interval,fn=fn,cancels=0}
        function t:Cancel() self.cancels=self.cancels+1 end
        tickers[#tickers+1]=t;return t
    end}
    assert(load("local rangePollTicker, EnsureRangePoll\n"..text.."\nreturn EnsureRangePoll","@actual-range-owner","t",e))()
    local function frame(id,shown,supported)
        local f={id=id,unit=id,shown=shown,_fluxRangeEventSupported=supported}
        function f:IsVisible() reads=reads+1;return self.shown end
        return f
    end
    return e,state,frame,tickers,paints,function() return reads end
end

local function exercise(text,assertWork)
    local e,s,frame,tickers,paints,reads=fixture(text)
    for i=1,40 do s.frameArray[i]=frame("raid"..i,true,false) end
    e.FluxRaid_EnsureRangePoll()
    check(#tickers==1 and tickers[1].interval==.25,"first live owner starts the existing 250ms ticker")
    if assertWork then improved(reads()==1,"discovery stops after the first eligible raid cell") end
    local firstReads=reads()
    for _=1,20 do e.FluxRaid_EnsureRangePoll() end
    check(#tickers==1,"roster/reveal bursts do not replace the current ticker")
    if assertWork then improved(reads()-firstReads==20,"each repeated discovery needs only one visibility read") end
    tickers[1].fn()
    check(#paints==40 and paints[1]=="raid1" and paints[40]=="raid40","ticker paints every eligible raid cell")
    for i=1,39 do s.frameArray[i].shown=false end
    local before=reads();e.FluxRaid_EnsureRangePoll()
    check(reads()-before==40 and #tickers==1,"late live owner is still found after hidden cells")
    s.partyRangeFrames[1]=frame("party1",true,false)
    s.partyRangeFrames[2]=frame("party2",true,false)
    s.partyRangeFrames[3]=frame("party3",true,true)
    s.partyRangeFrames[4]=frame("party4",false,false)
    tickers[1].fn()
    check(#paints==43 and paints[41]=="raid40" and paints[42]=="party1" and paints[43]=="party2",
        "periodic paint visits both pools while skipping native-supported and hidden cells")
    s.frameArray[40].shown=false
    before=reads();e.FluxRaid_EnsureRangePoll()
    check(#tickers==1 and tickers[1].cancels==0,"party fallback keeps the ticker alive after leaving raid")
    if assertWork then improved(reads()-before==41,"party discovery stops at its first eligible owner") end
    e.enabled=false;e.FluxRaid_EnsureRangePoll()
    check(tickers[1].cancels==1,"disabling raid frames cancels fallback polling")
    e.enabled=true;e.FluxRaid_EnsureRangePoll()
    check(#tickers==2,"reenabling with a live party owner restarts polling")
    s.partyRangeFrames[1].unit=nil;s.partyRangeFrames[2].shown=false
    tickers[2].fn()
    check(tickers[2].cancels==1 and #paints==43,"ticker retires itself after the last live owner leaves")
    e.FluxRaid_EnsureRangePoll();check(#tickers==2,"empty/hidden/native-supported pools remain idle")
    s.partyRangeFrames[2].shown=true;e.FluxRaid_EnsureRangePoll()
    check(#tickers==3,"a later party join wakes polling")
    s.partyRangeFrames={};s.frameArray={};tickers[3].fn()
    check(tickers[3].cancels==1,"complete pool retirement cancels polling")
    local absent,empty,make=fixture(text);absent.C_Timer=nil
    empty.frameArray[1]=make("raid1",true,false);absent.FluxRaid_EnsureRangePoll()
    return firstReads
end

local firstReads=exercise(body,true)
-- A broad early exit in the paint pass would silently leave later frames stale.
local stopPaint,n=body:gsub("if "..needsPollName.."%(btn%) then","if "..needsPollName.."(btn) then if paint then FluxRaid_UpdateRange(btn); return true end",1)
check(n==1 and not pcall(exercise,stopPaint,false),"negative control rejects truncating the periodic paint pass")
-- Discovery still needs a genuine current eligible frame; it cannot assume
-- every nonempty pool needs a fallback ticker.
local assumeLive,n=body:gsub("local active="..needsPollName.."%(frame%)","local active=true",1)
check(n==1 and not pcall(exercise,assumeLive,false),"negative control rejects unconditional polling")
print("Raid range discovery: "..checks.." checks PASS; first-owner visibility reads="..firstReads.."; native timing pending")
