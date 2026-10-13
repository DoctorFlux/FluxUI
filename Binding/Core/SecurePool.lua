-- Binding/Core/SecureButtonPool.lua
-- Reduces GC pressure and CreateFrame overhead during binding apply.
--
-- WoW frame names are immutable after CreateFrame, so this pool creates
-- named frames on first acquisition and caches deactivated frames for
-- reuse when the same name is requested again (common on repeated
-- ApplyAll calls where chord->frame mappings are stable).
--
-- For truly new names, the pool falls through to CreateFrame.

local addonName, ns = ...
local Pool = {}

local TEMPLATE =
    "SecureActionButtonTemplate,SecureHandlerStateTemplate,SecureHandlerShowHideTemplate"
local FALLBACK_TEMPLATE =
    "SecureActionButtonTemplate,SecureHandlerStateTemplate"

local retired = {}
local totalCreated = 0

local function SpellBindHasSecureHandlerMixin(btn)
    if not btn then return false end
    return type(btn.WrapScript) == "function" or type(btn.Execute) == "function"
end

local function CreateNamedButton(name)
    totalCreated = totalCreated + 1
    local ok, btn = pcall(CreateFrame, "Button", name, UIParent, TEMPLATE)
    if ok and btn then return btn end
    ok, btn = pcall(CreateFrame, "Button", name, UIParent, FALLBACK_TEMPLATE)
    if ok and btn then return btn end
    return CreateFrame("Button", name, UIParent, "SecureActionButtonTemplate")
end

function Pool.Acquire(name)
    if type(name) ~= "string" or name == "" then return nil end

    local existing = _G[name]
    if existing and SpellBindHasSecureHandlerMixin(existing) then
        retired[name] = nil
        return existing
    end

    if existing and not SpellBindHasSecureHandlerMixin(existing) then
        if InCombatLockdown() then return existing end
        if UnregisterStateDriver then pcall(UnregisterStateDriver, existing, "form") end
        existing:SetAttribute("_onstate-form", nil)
        pcall(existing.Hide, existing)
        pcall(existing.SetParent, existing, nil)
        _G[name] = nil
    end

    local cachedBtn = retired[name]
    if cachedBtn and SpellBindHasSecureHandlerMixin(cachedBtn) then
        retired[name] = nil
        _G[name] = cachedBtn
        return cachedBtn
    end

    local btn = CreateNamedButton(name)
    if not btn then return nil end
    btn:SetSize(1, 1)
    btn:Hide()
    btn:SetAttribute("type", "macro")
    btn:SetAttribute("macrotext", "")
    btn:SetAttribute("flux-macrotext-hovercast", "")
    if btn.RegisterForClicks then
        pcall(btn.RegisterForClicks, btn, "AnyDown")
    end
    pcall(btn.SetAttribute, btn, "useOnKeyDown", true)
    pcall(btn.SetAttribute, btn, "pressAndHoldAction", true)
    _G[name] = btn
    return btn
end

--- Hidden type=click delegates. SecureActionButton Click(button) is one
--- OnClick with down omitted; press-and-hold then reads typerelease.
--- Binding override SABs must not use this: typerelease would double-cast
--- on key-up after the down already ran type=macro.
function Pool.ArmMacroDelegate(btn)
    if not btn or not btn.SetAttribute then
        return false
    end
    if btn.IsForbidden then
        local ok, forbidden = pcall(btn.IsForbidden, btn)
        if ok and forbidden then
            return false
        end
    end
    if btn.HasAccessConstraints then
        local ok, constrained = pcall(btn.HasAccessConstraints, btn)
        if ok and constrained then
            return false
        end
    end
    if btn.HasAnyForbiddenAspects then
        local aspect = Enum and Enum.ForbiddenAspect and Enum.ForbiddenAspect.ScriptedInput
        if aspect then
            local ok, forbidden = pcall(btn.HasAnyForbiddenAspects, btn, aspect)
            if ok and forbidden then
                return false
            end
        end
    end
    if btn.RegisterForClicks then
        pcall(btn.RegisterForClicks, btn, "AnyDown", "AnyUp")
    end
    btn:SetAttribute("typerelease", "macro")
    btn:SetAttribute("pressAndHoldAction", true)
    btn:SetAttribute("useOnKeyDown", true)
    btn:SetAttribute("unit", nil)
    btn:SetAttribute("checkmouseovercast", false)
    return true
end

function Pool.Retire(name)
    if type(name) ~= "string" or name == "" then return end
    if InCombatLockdown() then return end
    local btn = _G[name]
    if not btn then return end
    retired[name] = btn
end

function Pool.GetStats()
    local retiredCount = 0
    for _ in pairs(retired) do retiredCount = retiredCount + 1 end
    return {
        retired = retiredCount,
        totalCreated = totalCreated,
    }
end

_G.FluxSecureButtonPool = Pool
ns.FluxSecureButtonPool = Pool
