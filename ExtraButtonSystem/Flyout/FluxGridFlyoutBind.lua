--[[
    ExtraButtonSystem/Flyout/FluxGridFlyoutBind.lua
    PostClick right-click flyout opener for preset NonCombat grid buttons.
    Primary path on pre-DF clients where type2 macrotext /click proxies may not fire.
]]

FluxGridFlyout = FluxGridFlyout or {}
local G = FluxGridFlyout

--- Right-click type2 secure attributes deliver PostClick on mouse-up when
--- ActionButtonUseKeyDown=1, even though the widget uses RegisterForClicks("AnyDown").
--- Left-click flyouts use FluxFlyout.ShouldProcessFlyoutClick instead.
--- @param down boolean|nil PostClick down flag
--- @return boolean
function G.ShouldProcessRightClickFlyout(down)
    if GetCVarBool then
        local ok, useKeyDown = pcall(GetCVarBool, "ActionButtonUseKeyDown")
        if ok then
            if useKeyDown then
                return down == false
            end
            return down == true
        end
    end
    return down == false or down == nil
end

--- Open a flyout for a grid widget (dedupe + toggle-close semantics).
--- @param widget Frame
--- @param actions table
--- @param config table|nil
--- @return boolean true if flyout is open after the call
function G.OpenForWidget(widget, actions, config)
    if not widget or not actions or #actions == 0 then
        return false
    end
    if InCombatLockdown() then
        return false
    end
    if FluxFlyout and FluxFlyout.OpenFlyoutForButton then
        FluxFlyout.OpenFlyoutForButton(widget, actions, config)
    elseif FluxFlyoutFrame and FluxFlyoutFrame.ShowFlyout then
        FluxFlyoutFrame.ShowFlyout(widget, actions, config)
    else
        return false
    end
    return FluxFlyoutFrame and FluxFlyoutFrame.IsFlyoutOpenFor
        and FluxFlyoutFrame.IsFlyoutOpenFor(widget)
end

--- Hook PostClick on a grid preset widget to open a flyout on right-click (Lua path).
--- @param widget Frame SecureActionButton widget
--- @param openFn function Called when flyout should open
--- @param opts table|nil { hookKey = string } optional unique key per module
function G.BindRightClickFlyout(widget, openFn, opts)
    if not widget or not openFn or not widget.HookScript then
        return
    end
    opts = opts or {}
    local hookKey = opts.hookKey or "FluxGridFlyoutRC"
    if widget[hookKey] then
        return
    end
    widget[hookKey] = true

    widget:HookScript("PostClick", function(self, button, down)
        if button ~= "RightButton" then
            return
        end
        if not G.ShouldProcessRightClickFlyout(down) then
            return
        end
        if InCombatLockdown() then
            return
        end
        -- Secure type2/macrotext2 proxy may have already opened the flyout on this click
        if FluxFlyoutFrame and FluxFlyoutFrame.IsFlyoutOpenFor and FluxFlyoutFrame.IsFlyoutOpenFor(self) then
            return
        end
        if openFn then
            pcall(openFn)
        end
    end)
end

_G.FluxGridFlyout = G
