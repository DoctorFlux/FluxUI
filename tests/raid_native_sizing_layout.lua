-- Production layout reservation arithmetic, without a game or secure widgets.
local checks=0
local function check(ok,label)checks=checks+1;assert(ok,label)end
local function fixture(source)
    local e=setmetatable({},{__index=_G});e._G=e
    e.FluxRaidState={pendingCombatWork={},raidHeaders={}}
    e.FluxRaidCompat={HEADER_UNIT_YOFFSET=4,MTMA_TARGET_HEIGHT=18,MTMA_TARGET_GAP=-4}
    e.FluxRaidVisuals={FRAME_WIDTH=98,FRAME_HEIGHT=44,MINI_FRAME_HEIGHT=22,CELL_JOIN_OVERLAP=1}
    e.CreateFrame=function()error("reading native size reservations must not allocate widgets")end
    assert(load(source,"@raid-layout-sizing","t",e))("_FluxUI",{})
    return e
end
local f=assert(io.open("RaidFrame/FluxRaidLayout.lua","rb"));local source=f:read("*a");f:close()
local e=fixture(source)
check(e.FluxRaid_GetColumnHeight()==216,"five stock44px cells share one-pixel borders")
check(e.FluxRaid_GetMTMAChildStep()==64,"stock44px main and22px mini reserve both shared joins")
e.FluxRaidVisuals.FRAME_HEIGHT=48;e.FluxRaidVisuals.MINI_FRAME_HEIGHT=24
check(e.FluxRaid_GetColumnHeight()==236,"column reservations follow new frame height without reloading the module")
check(e.FluxRaid_GetMTMAChildStep()==70,"mini reservations follow the active native-relative size")
e.FluxRaidCompat.MTMA_TARGET_HEIGHT=99;e.FluxRaidCompat.MTMA_TARGET_GAP=-19
check(e.FluxRaid_GetMTMAChildStep()==70,"old compatibility constants cannot override the current size policy")
local changed,n=source:gsub('FluxRaidVisuals%.MINI_FRAME_HEIGHT or Compat%.MTMA_TARGET_HEIGHT or 18','Compat.MTMA_TARGET_HEIGHT or 18',1)
check(n==1,"control targets stale mini-height reservation")
check(fixture(changed).FluxRaid_GetMTMAChildStep()~=64,"control rejects the old18px cached target strip")
local xmlfile=assert(io.open("RaidFrame/FluxRaidFrame.xml","rb"));local xml=xmlfile:read("*a");xmlfile:close()
check(xml:find('name="FluxRaidCellVisualTemplate"',1,true),"shared visual template is declared")
check(xml:find('name="FluxRaidUnitTemplate" inherits="FluxRaidCellVisualTemplate,SecureUnitButtonTemplate"',1,true),"live cell adds secure behavior to shared artwork")
local preview=assert(xml:match('<Button name="FluxRaidPreviewUnitTemplate"(.-)</Button>'))
check(preview:find('inherits="FluxRaidCellVisualTemplate"',1,true) and not preview:find('SecureUnitButtonTemplate',1,true),"preview inherits identical visuals without secure behavior")
check(not preview:find('<Layers>',1,true) and not preview:find('<Frames>',1,true),"preview cannot duplicate or drift from the cell artwork")
print("Raid native sizing layout: "..checks.." checks; actual column/mini reservations and shared preview/live XML; one rejected stale-height control")
