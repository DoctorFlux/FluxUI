--[[
    ExtraButtonSystem/Engine/FluxBtn.lua

    Facade for the shared ButtonForge-style action button engine.
    Primary namespace: FluxBtn. FluxButton remains the concrete class
    (alias for host code from ExtraButtons / Minimap).
]]

FluxBtn = FluxBtn or {}
local B = FluxBtn

B.VERSION = 1

--- Create a secure action button. config mirrors FluxButton.New options.
function B.Create(parent, config)
    if FluxButton and FluxButton.New then
        return FluxButton.New(parent, config)
    end
    return nil
end

B.New = B.Create

function B.ApplyStyle(button, scope)
    if FluxButtonUtil and FluxButtonUtil.ApplyButtonStyle then
        return FluxButtonUtil:ApplyButtonStyle(button, scope)
    end
end

function B.SafeGetItemCount(itemID, includeBank, includeCharges)
    if FluxButtonUtil and FluxButtonUtil.SafeGetItemCount then
        return FluxButtonUtil.SafeGetItemCount(itemID, includeBank, includeCharges)
    end
    if _G.FluxInv and _G.FluxInv.GetLiveCount then
        return _G.FluxInv.GetLiveCount(itemID, {
            includeBank = includeBank and true or false,
            charges = includeCharges ~= false,
        })
    end
    return 0
end

function B.Register(button)
    if FluxButtonEvents and FluxButtonEvents.RegisterButton then
        FluxButtonEvents.RegisterButton(button)
    end
end

function B.Unregister(button)
    if FluxButtonEvents and FluxButtonEvents.UnregisterButton then
        FluxButtonEvents.UnregisterButton(button)
    end
end

-- Alias: keep FluxButton as the concrete API hosts already call
B.Button = FluxButton
_G.FluxBtn = B
if FluxButton then
    _G.FluxButton = FluxButton
end
