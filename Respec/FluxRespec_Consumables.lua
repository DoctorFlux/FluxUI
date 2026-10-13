-- FluxRespec_Consumables.lua
-- Thin wrapper around FluxNCConsumables preset system. A Respec profile
-- only remembers the *name* of the consumables preset; the items inside are
-- owned by FluxNCConsumables (shared across Respec profiles).

FluxRespec = FluxRespec or {}
local R = FluxRespec
R.Consumables = R.Consumables or {}
local Consumables = R.Consumables

local function NC()
    return _G.FluxNCConsumables
end

--- Capture returns just the active preset name (string), or nil.
function Consumables.Capture()
    local nc = NC()
    if nc and nc.GetActivePreset then
        local ok, name = pcall(nc.GetActivePreset)
        if ok and type(name) == "string" and name ~= "" then
            return name
        end
    end
    return nil
end

--- Apply a preset by name. No-op if FluxNCConsumables not loaded or the
--- preset doesn't exist anymore.
function Consumables.Apply(presetName)
    if type(presetName) ~= "string" or presetName == "" then
        R.Fire("CONSUMABLES_APPLIED", true, "NOOP")
        return true
    end
    local nc = NC()
    if not nc or not nc.SetActivePreset then
        R.Fire("CONSUMABLES_APPLIED", false, "UNAVAILABLE")
        return false
    end

    -- Verify preset exists before attempting to switch.
    local exists = false
    if nc.GetPresetNames then
        local ok, list = pcall(nc.GetPresetNames)
        if ok and type(list) == "table" then
            for _, n in ipairs(list) do
                if n == presetName then
                    exists = true
                    break
                end
            end
        end
    else
        -- Fall back to assuming it exists.
        exists = true
    end

    if not exists then
        R.Warn(("Consumables preset '%s' no longer exists."):format(presetName))
        R.Fire("CONSUMABLES_APPLIED", false, "MISSING")
        return false
    end

    local ok = pcall(nc.SetActivePreset, presetName)
    R.Fire("CONSUMABLES_APPLIED", ok, ok and "DONE" or "ERROR")
    return ok
end

--- Does the active preset differ from the snapshot?
function Consumables.IsDifferent(presetName)
    if type(presetName) ~= "string" then return false end
    local active = Consumables.Capture()
    return active ~= presetName
end

R.Consumables = Consumables
