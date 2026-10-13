--[[
    Restock/Bank/FluxBankRestockNeed.lua

    Build a remaining-need map from session tasks (Flux restock targets).
]]

FluxBankRestockNeed = FluxBankRestockNeed or {}
local Need = FluxBankRestockNeed

--- Normalize tasks into need entries the planner consumes.
--- @param tasks table[] BuildTasks() output
--- @return table[] { task, itemID, remaining, maxStack, mode, tierKind, entry }
function Need.BuildFromTasks(tasks)
    local out = {}
    if not tasks then
        return out
    end
    for _, task in ipairs(tasks) do
        local remaining = math.floor(tonumber(task.remaining) or tonumber(task.withdraw) or 0)
        if remaining > 0 then
            local entry = task.entry
            out[#out + 1] = {
                task = task,
                entry = entry,
                itemID = tonumber(task.itemID) or (entry and tonumber(entry.itemID)),
                remaining = remaining,
                maxStack = tonumber(task.maxStack) or 20,
                mode = task.mode or (entry and entry.mode) or "stack",
                tierKind = entry and entry.isTierBankEntry and entry.tierKind or nil,
            }
        end
    end
    return out
end

--- Credit verified units against a task's remaining (and the need entry if provided).
function Need.Credit(task, needEntry, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then
        return 0
    end
    if task then
        local rem = math.floor(tonumber(task.remaining) or 0)
        local credit = math.min(amount, rem)
        task.remaining = math.max(0, rem - credit)
        if needEntry then
            needEntry.remaining = math.max(0, (tonumber(needEntry.remaining) or 0) - credit)
        end
        return credit
    end
    if needEntry then
        local rem = math.floor(tonumber(needEntry.remaining) or 0)
        local credit = math.min(amount, rem)
        needEntry.remaining = math.max(0, rem - credit)
        return credit
    end
    return 0
end

function Need.TotalRemaining(needs)
    local total = 0
    for _, n in ipairs(needs or {}) do
        total = total + math.max(0, math.floor(tonumber(n.remaining) or 0))
    end
    return total
end

_G.FluxBankRestockNeed = Need
return Need
