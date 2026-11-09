-- Binding/Aux/Slash.lua
-- /fluxbind entry points.

SLASH_FLUXBIND1 = "/fluxbind"

SlashCmdList["FLUXBIND"] = function(msg)
    msg = (msg or ""):match("^%s*(.-)%s*$") or ""
    local lower = string.lower(msg)
    if msg == "debug" then
        if _G.FluxBinding and _G.FluxBinding.Debug then
            _G.FluxBinding.Debug()
        end
        return
    end
    if msg == "apply" then
        if _G.FluxBinding and _G.FluxBinding.RequestApplyAll then
            _G.FluxBinding.RequestApplyAll("slash")
            print("|cff00ffff[FluxBinding]|r apply requested")
        end
        return
    end
    if lower == "viz" or lower == "visualizer" or lower == "keyboard" then
        local KV = _G.FluxKeyVisualizer
        if KV and KV.Open then
            KV:Open()
        elseif DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff4040Flux:|r KeyVisualizer not loaded")
        end
        return
    end
    if msg == "" then
        if _G.FluxSpellBindingEditor_Open then
            _G.FluxSpellBindingEditor_Open({ pending = true })
        elseif _G.FluxOptions and _G.FluxOptions.OpenToBindingTab then
            _G.FluxOptions:OpenToBindingTab()
        end
        return
    end
    local n = tonumber(msg)
    if n and n > 0 and _G.FluxSpellBindingEditor_Open then
        _G.FluxSpellBindingEditor_Open({ spellID = n, actionID = n })
    elseif DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4040Flux:|r Usage: /fluxbind [spellId|viz|apply|debug]")
    end
end
