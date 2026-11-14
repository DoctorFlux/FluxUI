-- Actual restock/selected-mail owner cadence; native server boundaries are mocked.
local checks, profiles = 0, 0
local function check(value, text) checks = checks + 1; assert(value, text) end
local export = setmetatable({ FLUX_MAIL_RESTOCK_FIXTURE_EXPORT = true }, { __index = _G })
local boot = assert(loadfile('tests/mail_restock.lua', 't', export))()
local measure = os.getenv('FLUX_MAIL_SPEED_MEASURE') == '1'
local function message(items, subject)
    return { sender = 'Auction House', subject = subject or 'Auction won', money = 0, cod = 0, items = items }
end
local function item(id) return { id = id or 101, quantity = 1 } end
local function begin(client, provider, timers, speed, many)
    local s = boot(client, provider, timers)
    s.mail.SetSetting('OpenSpeed', nil, speed)
    s.wanted = { [101] = 3 }
    s.inbox = { message({ item(), item(), item() }) }
    if many then for i = 2, 200 do s.inbox[i] = message({ item(202) }, 'Unrelated ' .. i) end end
    s:show(); s:update()
    for _ = 1, 1000 do if #s.calls > 0 then break end; s:pumpFrames(1) end
    check(#s.calls == 1 and #s.snapshots == 1, 'one complete initial snapshot starts one owned attachment')
    return s
end
local function untilCall(s, count)
    s:advance(0)
    for _ = 1, 10000 do if #s.calls >= count then return end; s:advance(.001) end
    error('restock did not progress after an acknowledged take')
end
for _, client in ipairs({ 'retail', 'forever', 'era', 'anniversary', 'mists' }) do
 for _, provider in ipairs({ 'builtin', 'syndicator' }) do
  for _, timers in ipairs({ false, true }) do
    profiles = profiles + 1
    for _, speed in ipairs({ 0, .05, .3, .5, 1, 5 }) do
        local s = begin(client, provider, timers, speed)
        for n = 2, 3 do
            local prior = s.calls[#s.calls].at
            s:advance(prior + .2 - s.now)
            local acknowledged = s.now
            s:ack(); untilCall(s, n)
            local expected = math.max(prior + speed, acknowledged)
            if not measure then check(math.abs(s.calls[n].at - expected) < .000001,
                'restock request interval follows OpenSpeed without adding reply latency: ' .. client .. '/' .. speed) end
            check(#s.calls == n and s.pending, 'next take stays single and waits for its own native acknowledgement')
        end
        if measure then print(('MAIL_SPEED %s %s %s %.2f %.6f %.6f %.6f'):format(client, provider, tostring(timers), speed,
            s.calls[1].at, s.calls[2].at, s.calls[3].at)) end
        s:ack(); s:advance(math.max(speed, .5))
        check(#s.calls == 3 and not s.mail.GetJobGroup() and not s.snapshots[#s.snapshots][101],
            'completion takes exactly three attachments and publishes their absence')
    end
    if not measure then
        -- A full-inbox rescan cannot fit between very fast takes. Initial proof,
        -- live header/slot validation and acknowledged receipt budgets remain.
        local s = begin(client, provider, timers, .05, true)
        s:advance(.02); s:ack(); s:advance(.03)
        check(#s.calls == 2 and math.abs(s.calls[2].at - .05) < .000001,
            'restock does not wait for a second full-inbox scan between proven attachments')
        check(#s.snapshots == 1 and s.maxSliceReads <= 48, 'full snapshot still obeys its48-read budget and is not fabricated early')

        s = begin(client, provider, timers, .5)
        s:advance(.2); s:ack(); s.mail.SetSetting('OpenSpeed', nil, .3)
        s:advance(.1)
        check(#s.calls == 2 and math.abs(s.calls[2].at - .3) < .000001, 'a faster saved setting updates the active restock deadline')

        s = begin(client, provider, timers, .3)
        s:advance(.1); s:ack(); s.mail.SetSetting('OpenSpeed', nil, 1)
        s:advance(.899)
        check(#s.calls == 1, 'slowing the setting cannot leave an old early take armed')
        s:advance(.001)
        check(#s.calls == 2 and math.abs(s.calls[2].at - 1) < .000001, 'slower cadence remains exact after the stale wake')

        s = begin(client, provider, timers, 0)
        s:advance(1)
        check(#s.calls == 1, 'zero speed never overlaps an unacknowledged native command')
        s:close(); s.pending = false; s:advance(10)
        check(#s.calls == 1, 'closing mail cancels every queued take')
    end
  end
 end
end
print(('Restock mail cadence: %d checks PASS/%d client-provider-timer profiles; native throughput NOT RUN'):format(checks, profiles))
