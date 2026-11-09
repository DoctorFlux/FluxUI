-- CombatQueue.lua
-- Shared combat-safe execution helper for ConsolePort compatibility actions.

local addonName, ns = ...

ns.ConsolePortCompat = ns.ConsolePortCompat or {}
local Compat = ns.ConsolePortCompat

local queue = {}

local function IsInCombat()
    return InCombatLockdown and InCombatLockdown()
end

function Compat.RunOrDefer(key, fn)
    if type(fn) ~= "function" then
        return false
    end

    if not IsInCombat() then
        fn()
        return true
    end

    local queueKey = key or tostring(fn)
    queue[queueKey] = fn
    return false
end

function Compat.HasDeferredWork()
    return next(queue) ~= nil
end

function Compat.FlushDeferred()
    if IsInCombat() then
        return false
    end

    local pending = queue
    queue = {}

    for _, fn in pairs(pending) do
        pcall(fn)
    end

    return true
end
