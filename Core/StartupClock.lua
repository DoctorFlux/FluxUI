-- First addon instruction, before embedded libraries. Two samples; no driver.
local _, ns = ...
ns.startupClock = GetTimePreciseSec and function() return GetTimePreciseSec() * 1000 end
    or debugprofilestop or function() return (GetTime and GetTime() or 0) * 1000 end
ns.startupBegan = ns.startupClock()
ns.startupMemory = collectgarbage and collectgarbage("count")
