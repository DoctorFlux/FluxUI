local addonName, ns = ...

local AceConfig       = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDB           = LibStub("AceDB-3.0")
local AceDBOptions    = LibStub("AceDBOptions-3.0")
local AceGUI          = LibStub("AceGUI-3.0")
local GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata

-- ---------------------------------------------------------------------------
-- Global handle - other modules access settings via FluxOptions.db.profile.*
-- ---------------------------------------------------------------------------
FluxOptions = FluxOptions or {}

-- ---------------------------------------------------------------------------
-- Module option builders stay queued until the shell opens that page.
-- The player window is FluxOptionsShell, not AceConfigDialog.
-- ---------------------------------------------------------------------------
local options = {
    name = "FluxUI",
    type = "group",
    childGroups = "tab",
    args = {},
}

-- Ace AddToBlizOptions: first return = Bliz options panel frame; second = numeric Settings category ID (DF+) or frame.name (legacy).
local blizzardAddonOptionsPanelFrame
local blizzardAddonSettingsCategoryID

local pendingModuleOptions = {} -- key -> options table or builder function
local optionsUIReady = false
local blizzardOptionsRegistered = false

local function ResolveModuleOptionsEntry(entry)
    if type(entry) == "function" then
        return entry()
    end
    return entry
end

local function ApplyModuleOptions(key, entry)
    local optionsTable = ResolveModuleOptionsEntry(entry)
    if not optionsTable then
        return
    end
    options.args[key] = optionsTable
end

local function HookBlizzardOptionsPanelShow()
    local panel = blizzardAddonOptionsPanelFrame
    if not panel then
        return
    end
    if panel._fluxEnsureOptionsHooked then
        return
    end
    panel._fluxEnsureOptionsHooked = true
    if panel.HookScript then
        panel:HookScript("OnShow", function()
            if FluxOptions and FluxOptions.EnsureOptionsUI then
                FluxOptions:EnsureOptionsUI()
            end
        end)
    elseif panel.SetScript then
        local prev = panel:GetScript("OnShow")
        panel:SetScript("OnShow", function(self, ...)
            if FluxOptions and FluxOptions.EnsureOptionsUI then
                FluxOptions:EnsureOptionsUI()
            end
            if prev then
                prev(self, ...)
            end
        end)
    end
end

--- True once the database exists and the options shell may open.
function FluxOptions:IsOptionsUIReady()
    return optionsUIReady
end

--- Mark the shell ready. Page tables are built the first time that page is shown.
function FluxOptions:EnsureOptionsUI()
    if not self.db then
        return false
    end
    optionsUIReady = true
    return true
end

function FluxOptions:GetModuleGen(key)
    return (self._moduleGen and self._moduleGen[key]) or 0
end

--- Resolve one module's Ace group. Does not build the other pages.
function FluxOptions:ResolveModuleOptions(key)
    self._moduleTables = self._moduleTables or {}
    if self._moduleTables[key] then
        return self._moduleTables[key]
    end
    local entry = pendingModuleOptions[key]
    if not entry then
        return nil
    end
    local optionsTable
    if type(entry) == "function" then
        optionsTable = entry()
    else
        optionsTable = entry
    end
    self._moduleTables[key] = optionsTable
    return optionsTable
end

function FluxOptions:GetProfilesOptions()
    if not self.db then
        return nil
    end
    return AceDBOptions:GetOptionsTable(self.db)
end

function FluxOptions:RefreshOpenPage()
    local shell = ns.FluxOptionsShell
    if shell and shell.RefreshOpenPage then
        shell:RefreshOpenPage()
    end
end

-- ---------------------------------------------------------------------------
-- Public API: let any module inject its own options tab (queued until EnsureOptionsUI)
-- ---------------------------------------------------------------------------
--- Register a module options tab. `optionsTableOrBuilder` may be an AceConfig
--- group table or a function that returns one (preferred for large tabs).
function FluxOptions:RegisterModuleOptions(key, optionsTableOrBuilder)
    if not key or not optionsTableOrBuilder then
        return
    end
    pendingModuleOptions[key] = optionsTableOrBuilder
    self._moduleTables = self._moduleTables or {}
    self._moduleTables[key] = nil
    self._moduleGen = self._moduleGen or {}
    self._moduleGen[key] = (self._moduleGen[key] or 0) + 1
    if optionsUIReady then
        self:RefreshOpenPage()
    end
end

-- Convenience accessor so modules don't need to know about AceDB internals.
function FluxOptions:GetDB()
    return self.db
end

-- ---------------------------------------------------------------------------
-- Account / Character profile helpers
-- ---------------------------------------------------------------------------
local ACCOUNT_PROFILE = "Default"

function FluxOptions:GetCharacterProfileName()
    local PN = _G.Flux and _G.Flux.PlayerName
    if PN and PN.GetCharKey then
        return PN.GetCharKey("profile") or "Char - Unknown - Unknown"
    end
    local name, realm
    if not (PN and PN.UsesRegionalUniqueNames and PN.UsesRegionalUniqueNames()) then
        name, realm = UnitFullName("player")
    end
    if not name or name == "" then name = UnitName("player") end
    if not realm or realm == "" then realm = GetRealmName() end
    return "Char - " .. (name or "Unknown") .. " - " .. (realm or "Unknown")
end

--- True when player/realm are available (not during early ADDON_LOADED). Required before SetProfile to a Char-* profile name.
function FluxOptions:IsCharacterProfileNameReady()
    local PN = _G.Flux and _G.Flux.PlayerName
    if PN and PN.IsCharacterIdentityReady then
        return PN.IsCharacterIdentityReady()
    end
    local name = UnitName("player")
    local realm = GetRealmName()
    return name and name ~= "" and realm and realm ~= ""
end

--- Apply account vs character profile after login. Must run once player name is valid, otherwise Char-* names become "Unknown" and overwrite the real per-character profile (losing custom accent, etc.).
function FluxOptions:EnforceProfileForLogin()
    local db = self.db
    if not db then return end

    if not self:IsCharacterProfileNameReady() then
        return
    end

    local charProfile = self:GetCharacterProfileName()
    if charProfile:find("Unknown", 1, true) then
        return
    end

    local unknownProfile = "Char - Unknown - Unknown"
    local current = db:GetCurrentProfile()

    -- Migrate data saved under the bad profile name from early-load SetProfile.
    if current == unknownProfile and charProfile ~= unknownProfile then
        db:SetProfile(charProfile)
        local profiles = db.sv and db.sv.profiles
        local destEmpty = not profiles or not profiles[charProfile] or not next(profiles[charProfile])
        if destEmpty and profiles and profiles[unknownProfile] and next(profiles[unknownProfile]) then
            db:CopyProfile(unknownProfile)
        end
        db.char.characterProfileInitialized = true
        db.char.useCharacterSpecific = true
        db.profile.settingsScope = "character"
        return
    end

    if db.char.useCharacterSpecific then
        if current ~= charProfile then
            db:SetProfile(charProfile)
        end
    else
        if current ~= ACCOUNT_PROFILE then
            db:SetProfile(ACCOUNT_PROFILE)
        end
    end
end

function FluxOptions:IsCharacterSpecific()
    if not self.db then return false end
    return self.db.char.useCharacterSpecific == true
end

function FluxOptions:SetCharacterSpecific(useChar)
    if not self.db then return end
    local db = self.db

    if useChar then
        if not self:IsCharacterProfileNameReady() then
            return
        end
        local charProfile = self:GetCharacterProfileName()
        db:SetProfile(charProfile)
        if not db.char.characterProfileInitialized then
            db:CopyProfile(ACCOUNT_PROFILE)
            db.char.characterProfileInitialized = true
        end
        db.char.useCharacterSpecific = true
        db.profile.settingsScope = "character"
    else
        db.char.useCharacterSpecific = false
        db.profile.settingsScope = "account"
        db:SetProfile(ACCOUNT_PROFILE)
    end
end

-- ---------------------------------------------------------------------------
-- Action bar options: scope independent of General -> Settings scope
-- (profile.actionbars vs char.actionbars)
-- ---------------------------------------------------------------------------

--- Deep copy table values so nested tables (e.g. extraButtonVisibility) are not shared between profile and char.
local function DeepCopyValue(v)
    if type(v) ~= "table" then
        return v
    end
    local t = {}
    for k, val in pairs(v) do
        t[k] = DeepCopyValue(val)
    end
    return t
end

local function CopyActionbarsFields(from, to)
    if not from or not to then
        return
    end
    for k in pairs(to) do
        to[k] = nil
    end
    for k, v in pairs(from) do
        to[k] = DeepCopyValue(v)
    end
end

function FluxOptions:IsActionbarsCharacterSpecific()
    if not self.db then
        return false
    end
    return self.db.char.actionbarsSettingsScope == "character"
end

--- Effective storage for Action Bars tab options (minirow layout, etc.).
function FluxOptions:GetActionbarsDB()
    local db = self.db
    if not db then
        return nil
    end
    if self:IsActionbarsCharacterSpecific() then
        if not db.char.actionbars then
            db.char.actionbars = {}
        end
        return db.char.actionbars
    end
    if not db.profile.actionbars then
        db.profile.actionbars = {}
    end
    return db.profile.actionbars
end

--- Toggle Action Bars scope. Does not call SetCharacterSpecific / change the active AceDB profile key.
function FluxOptions:SetActionbarsCharacterSpecific(useChar)
    local db = self.db
    if not db then
        return
    end

    -- stanceBarSlotOrder / stanceBarHiddenSlots are always character-specific; preserve across scope switches.
    local savedStanceOrder = db.char.actionbars and DeepCopyValue(db.char.actionbars.stanceBarSlotOrder)
    local savedStanceHidden = db.char.actionbars and DeepCopyValue(db.char.actionbars.stanceBarHiddenSlots)

    if useChar then
        if not db.char.actionbars then
            db.char.actionbars = {}
        end
        if not db.profile.actionbars then
            db.profile.actionbars = {}
        end
        CopyActionbarsFields(db.profile.actionbars, db.char.actionbars)
        db.char.actionbarsSettingsScope = "character"
        db.char.actionbarsCharInitialized = true
    else
        if not db.profile.actionbars then
            db.profile.actionbars = {}
        end
        if db.char.actionbars then
            CopyActionbarsFields(db.char.actionbars, db.profile.actionbars)
        end
        db.char.actionbarsSettingsScope = "account"
    end

    if db.char.actionbars then
        db.char.actionbars.stanceBarSlotOrder = savedStanceOrder or {}
        db.char.actionbars.stanceBarHiddenSlots = savedStanceHidden or {}
    end
    self:RefreshActionbarsScopedModules()
    if FluxExtraButtonVisibility and FluxExtraButtonVisibility.NotifyChanged then
        FluxExtraButtonVisibility.NotifyChanged()
    end
end

--- Re-apply minirow, mouseover, and spell rank UI from GetActionbarsDB() after profile or Action Bars scope change.
function FluxOptions:RefreshActionbarsScopedModules()
    local Flux = ns.Flux
    if Flux and Flux.Bars and Flux.Bars.ApplyActionbarsOptions then
        Flux.Bars.ApplyActionbarsOptions()
    elseif Flux and Flux.Bars and Flux.Bars.RequestLayout then
        Flux.Bars.RequestLayout("minirow")
    end
    local MC = _G.FluxMouseoverCast or (Flux and Flux.MouseoverCast)
    if MC and MC.Apply then
        MC.Apply()
    end
    local SR = FluxSpellRankManager or FluxSpellRankManagerModule
    if SR and SR.RefreshAfterActionbarsScopedStorageChange then
        SR:RefreshAfterActionbarsScopedStorageChange()
    end
    if FluxExtraButtonVisibility and FluxExtraButtonVisibility.NotifyChanged then
        FluxExtraButtonVisibility.NotifyChanged()
    end
    if FluxNCFlyoutOptions and FluxNCFlyoutOptions.NotifyChanged then
        FluxNCFlyoutOptions.NotifyChanged()
    end
    if _G.FluxUnitFrames_ApplyPlayerStatusBarLayout then
        pcall(_G.FluxUnitFrames_ApplyPlayerStatusBarLayout)
    end
    local Stance = Flux and Flux.Bars and Flux.Bars.Stance
    if Stance and Stance.RequestLayout then
        Stance.RequestLayout("options")
        if not InCombatLockdown() and Stance.ReassignBindings then
            Stance.ReassignBindings()
        end
    else
        local sb = _G.FluxStanceBar
        if sb and sb.UpdateLayout then
            sb:UpdateLayout()
            if not InCombatLockdown() and sb.ReassignBindings then
                sb:ReassignBindings()
            end
        end
    end
end

function FluxOptions:RefreshActionbarsAfterProfileChange()
    self:RefreshActionbarsScopedModules()
end

-- ---------------------------------------------------------------------------
-- Micro Menu tab storage (scale / spacing / drag order): microMenuSettingsScope on db.char (independent of Layout tab).
-- Per-button Off/Account/Character stays in FluxUI_DB.MicroMenu.native - not affected by either scope toggle.
-- Unified row order follows micro menu scope (FluxUI_DB vs _FluxUI_CharSavedVars unified* fields).
-- ---------------------------------------------------------------------------

local function CopyMicroMenuFields(from, to)
    if not from or not to then
        return
    end
    for k in pairs(to) do
        to[k] = nil
    end
    for k, v in pairs(from) do
        to[k] = DeepCopyValue(v)
    end
end

--- One-time: micromenu scope used to follow Layout tab scope; copy layout scope into micromenu scope, then diverge freely.
function FluxOptions:MigrateMicroMenuSettingsScopeFromLayoutOnce()
    local db = self.db
    if not db or not db.char then
        return
    end
    if db.char._fluxMMScopeSplitV1 then
        return
    end
    local layoutScope = (db.char.layoutSettingsScope == "character") and "character" or "account"
    db.char.microMenuSettingsScope = layoutScope
    db.char._fluxMMScopeSplitV1 = true
end

--- Micro Menu tab scope only (size, spacing, drag order + unified list). Not the Layout tab placement scope.
function FluxOptions:IsMicroMenuSettingsCharacterSpecific()
    if not self.db then
        return false
    end
    self:MigrateMicroMenuSettingsScopeFromLayoutOnce()
    return self.db.char.microMenuSettingsScope == "character"
end

--- Back-compat alias; same as IsMicroMenuSettingsCharacterSpecific.
function FluxOptions:IsMicroMenuLayoutCharacterSpecific()
    return self:IsMicroMenuSettingsCharacterSpecific()
end

function FluxOptions:GetMicroMenuDB()
    local db = self.db
    if not db then
        return nil
    end
    self:MigrateMicroMenuSettingsScopeFromLayoutOnce()
    if self:IsMicroMenuSettingsCharacterSpecific() then
        if not db.char.microMenu then
            db.char.microMenu = {}
        end
        return db.char.microMenu
    end
    if not db.profile.microMenu then
        db.profile.microMenu = {}
    end
    return db.profile.microMenu
end

--- Micro Menu tab: account vs character for size, spacing, and button order (not Layout placement).
function FluxOptions:SetMicroMenuSettingsCharacterSpecific(useChar)
    local db = self.db
    if not db then
        return
    end
    self:MigrateMicroMenuSettingsScopeFromLayoutOnce()

    if FluxMicroMenuConfig and FluxMicroMenuConfig.CopyUnifiedOrderForScopeToggle then
        FluxMicroMenuConfig:CopyUnifiedOrderForScopeToggle(useChar)
    end

    if useChar then
        if not db.char.microMenu then
            db.char.microMenu = {}
        end
        if not db.profile.microMenu then
            db.profile.microMenu = {}
        end
        CopyMicroMenuFields(db.profile.microMenu, db.char.microMenu)
        db.char.microMenuSettingsScope = "character"
        db.char.microMenuCharInitialized = true
    else
        if not db.profile.microMenu then
            db.profile.microMenu = {}
        end
        if db.char.microMenu then
            CopyMicroMenuFields(db.char.microMenu, db.profile.microMenu)
        end
        db.char.microMenuSettingsScope = "account"
    end
    self:RefreshMicroMenuScopedModules()
end

--- Kept for API/embed callers; delegates to SetMicroMenuSettingsCharacterSpecific.
function FluxOptions:SetMicroMenuLayoutCharacterSpecific(useChar)
    self:SetMicroMenuSettingsCharacterSpecific(useChar)
end

local function CopyLayoutFields(from, to)
    if not from or not to then
        return
    end
    for k in pairs(to) do
        to[k] = nil
    end
    for k, v in pairs(from) do
        to[k] = DeepCopyValue(v)
    end
end

function FluxOptions:IsLayoutCharacterSpecific()
    if not self.db then
        return false
    end
    return self.db.char.layoutSettingsScope == "character"
end

--- Layout tab storage (profile.layout vs char.layout); independent of General -> Settings scope.
function FluxOptions:GetLayoutDB()
    local db = self.db
    if not db then
        return nil
    end
    if self:IsLayoutCharacterSpecific() then
        if not db.char.layout then
            db.char.layout = {}
        end
        return db.char.layout
    end
    if not db.profile.layout then
        db.profile.layout = {}
    end
    return db.profile.layout
end

function FluxOptions:SetLayoutCharacterSpecific(useChar)
    local db = self.db
    if not db then
        return
    end

    if useChar then
        if not db.char.layout then
            db.char.layout = {}
        end
        if not db.profile.layout then
            db.profile.layout = {}
        end
        CopyLayoutFields(db.profile.layout, db.char.layout)
        db.char.layoutSettingsScope = "character"
        db.char.layoutCharInitialized = true
    else
        if not db.profile.layout then
            db.profile.layout = {}
        end
        if db.char.layout then
            CopyLayoutFields(db.char.layout, db.profile.layout)
        end
        db.char.layoutSettingsScope = "account"
    end
    self:RefreshLayoutDependents()
end

--- Reset Layout tab fields to AceDB defaults for the active layout scope (profile.layout vs char.layout).
function FluxOptions:ResetLayoutToDefaults()
    if not self.db or not FluxOptionsDefaults then
        return
    end
    local src = self:IsLayoutCharacterSpecific() and FluxOptionsDefaults.char.layout
        or FluxOptionsDefaults.profile.layout
    if not src then
        return
    end
    local dest = self:GetLayoutDB()
    if not dest then
        return
    end
    CopyLayoutFields(DeepCopyValue(src), dest)
    self:RefreshLayoutDependents()
    local ACR = LibStub and LibStub("AceConfigRegistry-3.0", true)
    if ACR then
        ACR:NotifyChange("FluxUI")
    end
    if _G.FluxLayoutPreviewUI and FluxLayoutPreviewUI.DrawPreview then
        FluxLayoutPreviewUI:DrawPreview()
    end
end

local function CopyWindowMoverFields(from, to)
    if not from or not to then
        return
    end
    for k in pairs(to) do
        to[k] = nil
    end
    for k, v in pairs(from) do
        to[k] = DeepCopyValue(v)
    end
    if type(to.frames) ~= "table" then
        to.frames = {}
    end
end

function FluxOptions:IsWindowMoverCharacterSpecific()
    if not self.db then
        return false
    end
    return self.db.char.windowMoverSettingsScope == "character"
end

--- Windows tab storage (profile.windowMover vs char.windowMover); independent of Layout / General.
function FluxOptions:GetWindowMoverDB()
    local db = self.db
    if not db then
        return nil
    end
    if self:IsWindowMoverCharacterSpecific() then
        if not db.char.windowMover then
            db.char.windowMover = {}
        end
        if type(db.char.windowMover.frames) ~= "table" then
            db.char.windowMover.frames = {}
        end
        return db.char.windowMover
    end
    if not db.profile.windowMover then
        db.profile.windowMover = {}
    end
    if type(db.profile.windowMover.frames) ~= "table" then
        db.profile.windowMover.frames = {}
    end
    return db.profile.windowMover
end

function FluxOptions:SetWindowMoverCharacterSpecific(useChar)
    local db = self.db
    if not db then
        return
    end

    if useChar then
        if not db.char.windowMover then
            db.char.windowMover = {}
        end
        if not db.profile.windowMover then
            db.profile.windowMover = {}
        end
        CopyWindowMoverFields(db.profile.windowMover, db.char.windowMover)
        db.char.windowMoverSettingsScope = "character"
        db.char.windowMoverCharInitialized = true
    else
        if not db.profile.windowMover then
            db.profile.windowMover = {}
        end
        if db.char.windowMover then
            CopyWindowMoverFields(db.char.windowMover, db.profile.windowMover)
        end
        db.char.windowMoverSettingsScope = "account"
    end
    self:RefreshWindowMoverDependents()
end

function FluxOptions:ResetWindowMoverToDefaults()
    if not self.db or not FluxOptionsDefaults then
        return
    end
    local src = self:IsWindowMoverCharacterSpecific() and FluxOptionsDefaults.char.windowMover
        or FluxOptionsDefaults.profile.windowMover
    if not src then
        return
    end
    local dest = self:GetWindowMoverDB()
    if not dest then
        return
    end
    CopyWindowMoverFields(DeepCopyValue(src), dest)
    self:RefreshWindowMoverDependents()
    local ACR = LibStub and LibStub("AceConfigRegistry-3.0", true)
    if ACR then
        ACR:NotifyChange("FluxUI")
    end
end

function FluxOptions:RefreshWindowMoverDependents()
    local FluxNS = _G.Flux
    local WM = FluxNS and FluxNS.WindowMover
    if WM and WM.Refresh then
        WM.Refresh()
    end
end

--- 1 = horizontal top bar; 2 = vertical strip left of chat; 3 = vertical strip beside minimap (popup).
function FluxOptions:GetMicroMenuLayoutPosition()
    local d = self:GetLayoutDB()
    local p = d and d.microMenuPosition
    if type(p) == "string" then
        p = tonumber(p)
    end
    if p == 2 then
        return 2
    end
    if p == 3 then
        return 3
    end
    return 1
end

--- Position 2 and 3: vertical grid detached from unified micro+status stack (same status bar anchoring as position 2).
function FluxOptions:IsMicroMenuDetachedVerticalLayout()
    local p = self:GetMicroMenuLayoutPosition()
    return p == 2 or p == 3
end

--- Position 3 only: minimap strip expanded (false = collapsed to chevron only).
function FluxOptions:GetMicroMenuMinimapStripExpanded()
    local d = self:GetLayoutDB()
    local v = d and d.microMenuMinimapStripExpanded
    return v == true
end

function FluxOptions:SetMicroMenuMinimapStripExpanded(expanded)
    local d = self:GetLayoutDB()
    if not d then
        return
    end
    d.microMenuMinimapStripExpanded = expanded and true or false
end

--- Position 2 and 3: micro buttons per row (1-8).
function FluxOptions:GetMicroMenuBesideChatColumns()
    local d = self:GetLayoutDB()
    local n = d and d.microMenuBesideChatColumns
    if type(n) == "string" then
        n = tonumber(n)
    end
    if type(n) ~= "number" then
        return 2
    end
    n = math.floor(n + 0.5)
    if n < 1 then
        return 1
    end
    if n > 8 then
        return 8
    end
    return n
end

--- "actionStrip" | "statusIntegrated" | "minimapTop" | "screenTopLeft".
--- Legacy "topLeft" stays on the action strip so older layouts do not jump.
function FluxOptions:GetInfoFramePlacement()
    local d = self:GetLayoutDB()
    local p = d and d.infoFramePlacement
    if p == "topLeft" then
        return "actionStrip"
    end
    if p == "statusIntegrated" or p == "minimapTop" or p == "screenTopLeft" then
        return p
    end
    return "actionStrip"
end

--- Where the info cell sits among gold / XP / reputation when placement is statusIntegrated.
--- "start" before the first bar, "middle" after the first bar, "end" after the last bar.
function FluxOptions:GetInfoStatusSlot()
    local d = self:GetLayoutDB()
    local s = d and d.infoStatusSlot
    if s == "middle" or s == "end" then
        return s
    end
    return "start"
end

--- 1 = under micro menu (stacked); 2 = horizontal strip above main action bar; 3 = full-width strip at screen bottom.
function FluxOptions:GetStatusBarPosition()
    local d = self:GetLayoutDB()
    local p = d and d.statusBarPosition
    if type(p) == "string" then
        p = tonumber(p)
    end
    if p == 2 then
        return 2
    end
    if p == 3 then
        return 3
    end
    return 1
end

--- 1 = player above bar stack + target top-center; 2 = target to the right of player (same bottom lift). See Layout tab.
function FluxOptions:GetPlayerTargetPlacement()
    local d = self:GetLayoutDB()
    local p = d and d.playerTargetPlacement
    if type(p) == "string" then
        p = tonumber(p)
    end
    if p == 2 then
        return 2
    end
    return 1
end

--- 1 = stance bar docked to Flux player chrome; 2 = same position as when Flux player is off (status strip / window). See Layout tab.
function FluxOptions:GetStanceBarPlacement()
    -- Gamepad HUD always uses placement 2. The saved value is left alone
    -- so leaving the HUD restores placement 1 (unit frame) or whatever was stored.
    local Cap = _G.Flux and _G.Flux.Cap
    if Cap and Cap.GamepadHudActive and Cap.GamepadHudActive() then
        return 2
    end
    local d = self:GetLayoutDB()
    local p = d and d.stanceBarPlacement
    if type(p) == "string" then
        p = tonumber(p)
    end
    if p == 2 then
        return 2
    end
    return 1
end

--- After micromenu / status bar / chat placement options change.
function FluxOptions:RefreshLayoutDependents()
    self:RefreshMicroMenuScopedModules()
end

function FluxOptions:RefreshMicroMenuScopedModules()
    if FluxMicroMenu and FluxMicroMenu.Rebuild then
        FluxMicroMenu:Rebuild()
    end
    if FluxMicroMenuConfigUI and FluxMicroMenuConfigUI.RefreshRows then
        FluxMicroMenuConfigUI:RefreshRows()
    end
    if _G.FluxStatusBarUpdateLayout then
        _G.FluxStatusBarUpdateLayout()
    end
    if _G.FluxPVPObjectiveMover and _G.FluxPVPObjectiveMover.UpdatePositions then
        _G.FluxPVPObjectiveMover.UpdatePositions()
    end
    if _G.FluxTalkingHead and _G.FluxTalkingHead.UpdatePosition then
        _G.FluxTalkingHead.UpdatePosition()
    end
    if _G.FluxChatFrame_ApplyPrimaryPosition then
        _G.FluxChatFrame_ApplyPrimaryPosition(true)
    end
    if _G.FluxUnifiedBorder and _G.FluxUnifiedBorder.UpdateBorder then
        _G.FluxUnifiedBorder.UpdateBorder()
    end
    if _G.FluxUnifiedBorder and _G.FluxUnifiedBorder.UpdateStatusBarBorder then
        _G.FluxUnifiedBorder.UpdateStatusBarBorder()
    end
    if _G.FluxInfoFrame and _G.FluxInfoFrame.ForceUpdatePosition then
        pcall(_G.FluxInfoFrame.ForceUpdatePosition)
    elseif _G.FluxInfoFrame and _G.FluxInfoFrame.UpdatePosition then
        pcall(_G.FluxInfoFrame.UpdatePosition)
    end
    if _G.FluxCombatManager and _G.FluxCombatManager.UpdateAnchor then
        pcall(_G.FluxCombatManager.UpdateAnchor, _G.FluxCombatManager)
    end
    -- Layout / status bar: main bar bottom offset and player screen Y must track (Notify may run before DB settles or skip in combat).
    if _G.FluxActionBar and _G.FluxActionBar.UpdatePosition then
        pcall(_G.FluxActionBar.UpdatePosition, _G.FluxActionBar)
    end
    if _G.FluxNonCombatGrid_ApplyScreenBottomAnchor then
        pcall(_G.FluxNonCombatGrid_ApplyScreenBottomAnchor)
    end
    if _G.FluxCombatManager and _G.FluxCombatManager.UpdateAnchor then
        pcall(_G.FluxCombatManager.UpdateAnchor, _G.FluxCombatManager)
    end
    if _G.FluxTrinketMenuManager and _G.FluxTrinketMenuManager.UpdateAnchor then
        pcall(_G.FluxTrinketMenuManager.UpdateAnchor, _G.FluxTrinketMenuManager)
    end
    if _G.FluxUnitFrames_ApplyPlayerStatusBarLayout then
        pcall(_G.FluxUnitFrames_ApplyPlayerStatusBarLayout)
    end
    if _G.FluxUnitFrames_FullUnitFrameLayoutRefresh then
        pcall(_G.FluxUnitFrames_FullUnitFrameLayoutRefresh)
    else
        if _G.FluxUnitFrames_ApplyFrameSizesFromDB then
            pcall(_G.FluxUnitFrames_ApplyFrameSizesFromDB)
        end
        if _G.FluxUnitFrames_ApplyAuraLayoutFromDB then
            pcall(_G.FluxUnitFrames_ApplyAuraLayoutFromDB)
        end
    end
    if _G.FluxStanceBar and _G.FluxStanceBar.Flux_ReanchorToLayout then
        pcall(_G.FluxStanceBar.Flux_ReanchorToLayout, _G.FluxStanceBar)
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            if InCombatLockdown() then
                return
            end
            if _G.FluxActionBar and _G.FluxActionBar.UpdatePosition then
                pcall(_G.FluxActionBar.UpdatePosition, _G.FluxActionBar)
            end
            if _G.FluxNonCombatGrid_ApplyScreenBottomAnchor then
                pcall(_G.FluxNonCombatGrid_ApplyScreenBottomAnchor)
            end
            if _G.FluxCombatManager and _G.FluxCombatManager.UpdateAnchor then
                pcall(_G.FluxCombatManager.UpdateAnchor, _G.FluxCombatManager)
            end
            if _G.FluxTrinketMenuManager and _G.FluxTrinketMenuManager.UpdateAnchor then
                pcall(_G.FluxTrinketMenuManager.UpdateAnchor, _G.FluxTrinketMenuManager)
            end
            if _G.FluxUnitFrames_ApplyPlayerStatusBarLayout then
                pcall(_G.FluxUnitFrames_ApplyPlayerStatusBarLayout)
            end
            if _G.FluxUnitFrames_FullUnitFrameLayoutRefresh then
                pcall(_G.FluxUnitFrames_FullUnitFrameLayoutRefresh)
            else
                if _G.FluxUnitFrames_ApplyFrameSizesFromDB then
                    pcall(_G.FluxUnitFrames_ApplyFrameSizesFromDB)
                end
                if _G.FluxUnitFrames_ApplyAuraLayoutFromDB then
                    pcall(_G.FluxUnitFrames_ApplyAuraLayoutFromDB)
                end
            end
            if _G.FluxStanceBar and _G.FluxStanceBar.Flux_ReanchorToLayout then
                pcall(_G.FluxStanceBar.Flux_ReanchorToLayout, _G.FluxStanceBar)
            end
        end)
    end
    --- Position 2: micromenu height uses chat top + grid border top; second pass after chat/border settle.
    --- Position 3: minimap height may settle after embed/resize; same second pass.
    if FluxOptions.IsMicroMenuDetachedVerticalLayout and FluxOptions:IsMicroMenuDetachedVerticalLayout()
        and FluxMicroMenu and FluxMicroMenu.Rebuild then
        C_Timer.After(0, function()
            if InCombatLockdown() then
                return
            end
            FluxMicroMenu:Rebuild()
        end)
    end
    if C_Timer and C_Timer.After and _G.FluxLayoutPreviewUI and FluxLayoutPreviewUI.DrawPreview then
        C_Timer.After(0, function()
            if _G.FluxLayoutPreviewUI and FluxLayoutPreviewUI.DrawPreview then
                FluxLayoutPreviewUI:DrawPreview()
            end
        end)
    end
end

function FluxOptions:ResetMicroMenuLayoutToDefaults()
    if not self.db or not FluxOptionsDefaults then
        return
    end
    local src = self:IsMicroMenuSettingsCharacterSpecific() and FluxOptionsDefaults.char.microMenu
        or FluxOptionsDefaults.profile.microMenu
    if not src then
        return
    end
    local dest = self:GetMicroMenuDB()
    if not dest then
        return
    end
    CopyMicroMenuFields(DeepCopyValue(src), dest)
    self:RefreshMicroMenuScopedModules()
end

function FluxOptions:RefreshMicroMenuAfterProfileChange()
    self:RefreshMicroMenuScopedModules()
end

--- Profile switch: refresh when either micromenu layout or Layout tab data is profile-bound.
function FluxOptions:RefreshLayoutScopedModulesAfterProfileChange()
    self:RefreshMicroMenuScopedModules()
end

-- ---------------------------------------------------------------------------
-- Raid & party frame options: scope independent of General -> Settings scope
-- (profile.raidFrames vs char.raidFrames)
-- ---------------------------------------------------------------------------

local function CopyRaidFramesFields(from, to)
    if not from or not to then
        return
    end
    for k in pairs(to) do
        to[k] = nil
    end
    for k, v in pairs(from) do
        to[k] = DeepCopyValue(v)
    end
end

function FluxOptions:IsRaidFramesCharacterSpecific()
    if not self.db then
        return false
    end
    return self.db.char.raidFramesSettingsScope == "character"
end

function FluxOptions:GetRaidFrameDB()
    local db = self.db
    if not db then
        return nil
    end
    if self:IsRaidFramesCharacterSpecific() then
        if not db.char.raidFrames then
            db.char.raidFrames = {}
        end
        return db.char.raidFrames
    end
    if not db.profile.raidFrames then
        db.profile.raidFrames = {}
    end
    return db.profile.raidFrames
end

function FluxOptions:SetRaidFrameCharacterSpecific(useChar)
    local db = self.db
    if not db then
        return
    end

    if useChar then
        if not db.char.raidFrames then
            db.char.raidFrames = {}
        end
        if not db.profile.raidFrames then
            db.profile.raidFrames = {}
        end
        CopyRaidFramesFields(db.profile.raidFrames, db.char.raidFrames)
        db.char.raidFramesSettingsScope = "character"
        db.char.raidFramesCharInitialized = true
    else
        if not db.profile.raidFrames then
            db.profile.raidFrames = {}
        end
        if db.char.raidFrames then
            CopyRaidFramesFields(db.char.raidFrames, db.profile.raidFrames)
        end
        db.char.raidFramesSettingsScope = "account"
    end
    self:RefreshRaidFrameScopedModules()
end

function FluxOptions:RefreshRaidFrameScopedModules()
    if FluxRaid_ApplyOptionsFromDB then
        FluxRaid_ApplyOptionsFromDB()
    end
    if FluxRaidPreview and FluxRaidPreview.RefreshFromOptions then
        FluxRaidPreview.RefreshFromOptions()
    end
end

--- Restore raid frame tab fields from FluxOptionsDefaults for the active raid scope (account profile vs char.raidFrames).
function FluxOptions:ResetRaidFramesToDefaults()
    if not self.db or not FluxOptionsDefaults then
        return
    end
    local src = self:IsRaidFramesCharacterSpecific() and FluxOptionsDefaults.char.raidFrames
        or FluxOptionsDefaults.profile.raidFrames
    if not src then
        return
    end
    local dest = self:GetRaidFrameDB()
    if not dest then
        return
    end
    CopyRaidFramesFields(DeepCopyValue(src), dest)
    self:RefreshRaidFrameScopedModules()
end

function FluxOptions:RefreshRaidFramesAfterProfileChange()
    self:RefreshRaidFrameScopedModules()
end

-- ---------------------------------------------------------------------------
-- Unit frame options: scope independent of General -> Settings scope
-- (profile.unitFrames vs char.unitFrames)
-- ---------------------------------------------------------------------------

local function CopyUnitFramesFields(from, to)
    if not from or not to then
        return
    end
    for k in pairs(to) do
        to[k] = nil
    end
    for k, v in pairs(from) do
        to[k] = DeepCopyValue(v)
    end
end

function FluxOptions:IsUnitFramesCharacterSpecific()
    if not self.db then
        return false
    end
    return self.db.char.unitFramesSettingsScope == "character"
end

function FluxOptions:GetUnitFrameDB()
    local db = self.db
    if not db then
        return nil
    end
    if self:IsUnitFramesCharacterSpecific() then
        if not db.char.unitFrames then
            db.char.unitFrames = {}
        end
        return db.char.unitFrames
    end
    if not db.profile.unitFrames then
        db.profile.unitFrames = {}
    end
    return db.profile.unitFrames
end

function FluxOptions:SetUnitFrameCharacterSpecific(useChar)
    local db = self.db
    if not db then
        return
    end

    if useChar then
        if not db.char.unitFrames then
            db.char.unitFrames = {}
        end
        if not db.profile.unitFrames then
            db.profile.unitFrames = {}
        end
        CopyUnitFramesFields(db.profile.unitFrames, db.char.unitFrames)
        db.char.unitFramesSettingsScope = "character"
        db.char.unitFramesCharInitialized = true
    else
        if not db.profile.unitFrames then
            db.profile.unitFrames = {}
        end
        if db.char.unitFrames then
            CopyUnitFramesFields(db.char.unitFrames, db.profile.unitFrames)
        end
        db.char.unitFramesSettingsScope = "account"
    end
    self:RefreshUnitFrameScopedModules()
end

function FluxOptions:RefreshUnitFrameScopedModules()
    if FluxUnitFrames_ApplyFluxVsBlizzardRuntime then
        FluxUnitFrames_ApplyFluxVsBlizzardRuntime()
    end
    if FluxUnitFrames_ApplyOptionsFromDB then
        FluxUnitFrames_ApplyOptionsFromDB()
    end
end

function FluxOptions:ResetUnitFramesToDefaults()
    if not self.db or not FluxOptionsDefaults then
        return
    end
    local src = self:IsUnitFramesCharacterSpecific() and FluxOptionsDefaults.char.unitFrames
        or FluxOptionsDefaults.profile.unitFrames
    if not src then
        return
    end
    local dest = self:GetUnitFrameDB()
    if not dest then
        return
    end
    CopyUnitFramesFields(DeepCopyValue(src), dest)
    self:RefreshUnitFrameScopedModules()
end

function FluxOptions:RefreshUnitFramesAfterProfileChange()
    self:RefreshUnitFrameScopedModules()
end

-- ---------------------------------------------------------------------------
-- Status bar strip options: scope independent of General -> Settings scope
-- (profile.statusBars vs char.statusBars). Item currency (gold bar) is always
-- stored in char.itemCurrency; see GetItemCurrencyDB. Honor/Arena on bar uses
-- _FluxUI_CharSavedVars.PVPTracking.
-- ---------------------------------------------------------------------------

--- Remove legacy itemCurrency nested under statusBars (now char.itemCurrency only).
local function StripItemCurrencyFromScopedStatusBars()
    if not FluxOptions or not FluxOptions.db then
        return
    end
    local db = FluxOptions.db
    if db.profile and db.profile.statusBars and db.profile.statusBars.itemCurrency ~= nil then
        db.profile.statusBars.itemCurrency = nil
    end
    if db.char and db.char.statusBars and db.char.statusBars.itemCurrency ~= nil then
        db.char.statusBars.itemCurrency = nil
    end
end

--- Tracked item counts on the gold bar: always per-character (independent of Status bar scope).
function FluxOptions:GetItemCurrencyDB()
    if not self.db or not self.db.char then
        return nil
    end
    local c = self.db.char
    if not c.itemCurrency or type(c.itemCurrency) ~= "table" then
        c.itemCurrency = {
            enabled = true,
            slots = {
                { itemId = 0, show = false },
            },
        }
    end
    if c.itemCurrency.slots == nil or type(c.itemCurrency.slots) ~= "table" then
        c.itemCurrency.slots = {}
    end
    for i = 1, math.max(#c.itemCurrency.slots, 1) do
        if c.itemCurrency.slots[i] == nil then
            c.itemCurrency.slots[i] = { itemId = 0, show = false }
        else
            local r = c.itemCurrency.slots[i]
            r.itemId = (type(r.itemId) == "number" and r.itemId) or (tonumber(r.itemId) or 0)
            r.show = r.show and true or false
        end
    end
    if c._fluxICStorageV1 ~= true then
        local function hasAnyId(tbl)
            if not tbl or type(tbl.slots) ~= "table" then
                return false
            end
            for i = 1, #tbl.slots do
                if tbl.slots[i] and (tbl.slots[i].itemId or 0) > 0 then
                    return true
                end
            end
            return (tbl.enabled == true)
        end
        local destEmpty = not hasAnyId(c.itemCurrency)
        if destEmpty then
            if c.statusBars and c.statusBars.itemCurrency and hasAnyId(c.statusBars.itemCurrency) then
                c.itemCurrency.enabled = c.statusBars.itemCurrency.enabled and true or false
                for i = 1, 6 do
                    if c.statusBars.itemCurrency.slots and c.statusBars.itemCurrency.slots[i] then
                        c.itemCurrency.slots[i] = c.itemCurrency.slots[i] or { itemId = 0, show = false }
                        c.itemCurrency.slots[i].itemId = c.statusBars.itemCurrency.slots[i].itemId or 0
                        c.itemCurrency.slots[i].show = c.statusBars.itemCurrency.slots[i].show and true or false
                    end
                end
            elseif self.db.profile
                and self.db.profile.statusBars
                and self.db.profile.statusBars.itemCurrency
                and hasAnyId(self.db.profile.statusBars.itemCurrency)
            then
                local src = self.db.profile.statusBars.itemCurrency
                c.itemCurrency.enabled = src.enabled and true or false
                for i = 1, 6 do
                    if src.slots and src.slots[i] then
                        c.itemCurrency.slots[i] = c.itemCurrency.slots[i] or { itemId = 0, show = false }
                        c.itemCurrency.slots[i].itemId = src.slots[i].itemId or 0
                        c.itemCurrency.slots[i].show = src.slots[i].show and true or false
                    end
                end
            end
        end
        c._fluxICStorageV1 = true
    end
    if FluxItemCurrencyTracking and FluxItemCurrencyTracking.MaintainItemCurrencySlotList then
        pcall(FluxItemCurrencyTracking.MaintainItemCurrencySlotList, c.itemCurrency)
    end
    StripItemCurrencyFromScopedStatusBars()
    return c.itemCurrency
end

local function CopyStatusBarsFields(from, to)
    if not from or not to then
        return
    end
    for k in pairs(to) do
        to[k] = nil
    end
    for k, v in pairs(from) do
        to[k] = DeepCopyValue(v)
    end
end

function FluxOptions:IsStatusBarsCharacterSpecific()
    if not self.db then
        return false
    end
    return self.db.char.statusBarsSettingsScope == "character"
end

--- Effective storage for Status Bars tab (currency strip on/off, shared height).
function FluxOptions:GetStatusBarSettingsDB()
    local db = self.db
    if not db then
        return nil
    end
    if self:IsStatusBarsCharacterSpecific() then
        if not db.char.statusBars then
            db.char.statusBars = {}
        end
        return db.char.statusBars
    end
    if not db.profile.statusBars then
        db.profile.statusBars = {}
    end
    return db.profile.statusBars
end

function FluxOptions:SetStatusBarsCharacterSpecific(useChar)
    local db = self.db
    if not db then
        return
    end

    if useChar then
        if not db.char.statusBars then
            db.char.statusBars = {}
        end
        if not db.profile.statusBars then
            db.profile.statusBars = {}
        end
        CopyStatusBarsFields(db.profile.statusBars, db.char.statusBars)
        db.char.statusBarsSettingsScope = "character"
        db.char.statusBarsCharInitialized = true
    else
        if not db.profile.statusBars then
            db.profile.statusBars = {}
        end
        if db.char.statusBars then
            CopyStatusBarsFields(db.char.statusBars, db.profile.statusBars)
        end
        db.char.statusBarsSettingsScope = "account"
    end
    StripItemCurrencyFromScopedStatusBars()
    self:RefreshStatusBarScopedModules()
end

local function RefreshStatusBarActionStripAnchors()
    if _G.FluxActionBar and _G.FluxActionBar.UpdatePosition then
        pcall(_G.FluxActionBar.UpdatePosition, _G.FluxActionBar)
    end
    if _G.FluxWindowFrame and _G.FluxWindowFrame.ApplyBottomLiftFromStatusBar then
        pcall(_G.FluxWindowFrame.ApplyBottomLiftFromStatusBar, _G.FluxWindowFrame)
    end
    if _G.FluxNonCombatGrid_ApplyScreenBottomAnchor then
        pcall(_G.FluxNonCombatGrid_ApplyScreenBottomAnchor)
    end
    if _G.FluxCombatManager and _G.FluxCombatManager.UpdateAnchor then
        pcall(_G.FluxCombatManager.UpdateAnchor, _G.FluxCombatManager)
    end
    if _G.FluxTrinketMenuManager and _G.FluxTrinketMenuManager.UpdateAnchor then
        pcall(_G.FluxTrinketMenuManager.UpdateAnchor, _G.FluxTrinketMenuManager)
    end
    if _G.FluxInfoFrame and _G.FluxInfoFrame.UpdatePosition then
        pcall(_G.FluxInfoFrame.UpdatePosition)
    end
    if _G.FluxUnifiedBorder and _G.FluxUnifiedBorder.UpdateBorder then
        pcall(_G.FluxUnifiedBorder.UpdateBorder)
    end
    if _G.FluxUnifiedBorder and _G.FluxUnifiedBorder.UpdateStatusBarBorder then
        pcall(_G.FluxUnifiedBorder.UpdateStatusBarBorder)
    end
    if _G.FluxUnitFrames_ApplyPlayerStatusBarLayout then
        pcall(_G.FluxUnitFrames_ApplyPlayerStatusBarLayout)
    end
end

--- Multi-pass status bar layout + action-strip anchor settle (options changes and login/reload).
function _G.FluxStatusBar_ScheduleActionStripAnchorSettle(includeLayoutUpdate)
    if includeLayoutUpdate and _G.FluxStatusBarUpdateLayout then
        pcall(_G.FluxStatusBarUpdateLayout)
    end
    RefreshStatusBarActionStripAnchors()
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            if InCombatLockdown() then
                return
            end
            if includeLayoutUpdate and _G.FluxStatusBarUpdateLayout then
                pcall(_G.FluxStatusBarUpdateLayout)
            end
            RefreshStatusBarActionStripAnchors()
            C_Timer.After(0, function()
                if not InCombatLockdown() then
                    RefreshStatusBarActionStripAnchors()
                end
            end)
        end)
    end
end

function FluxOptions:RefreshStatusBarScopedModules()
    _G.FluxStatusBar_ScheduleActionStripAnchorSettle(true)
end

function FluxOptions:ResetStatusBarsToDefaults()
    if not self.db or not FluxOptionsDefaults then
        return
    end
    local src = self:IsStatusBarsCharacterSpecific() and FluxOptionsDefaults.char.statusBars
        or FluxOptionsDefaults.profile.statusBars
    if not src then
        return
    end
    local dest = self:GetStatusBarSettingsDB()
    if not dest then
        return
    end
    CopyStatusBarsFields(DeepCopyValue(src), dest)
    local ics = FluxOptionsDefaults and FluxOptionsDefaults.char and FluxOptionsDefaults.char.itemCurrency
    if ics and self.GetItemCurrencyDB then
        local d = self:GetItemCurrencyDB()
        if d then
            d.enabled = ics.enabled and true or false
            d.slots = DeepCopyValue(ics.slots) or { { itemId = 0, show = false } }
            if #d.slots < 1 or type(d.slots) ~= "table" then
                d.slots = { { itemId = 0, show = false } }
            end
            if _G.FluxItemCurrencyTracking and _G.FluxItemCurrencyTracking.MaintainItemCurrencySlotList then
                pcall(_G.FluxItemCurrencyTracking.MaintainItemCurrencySlotList, d)
            end
        end
    end
    self:RefreshStatusBarScopedModules()
end

function FluxOptions:RefreshStatusBarsAfterProfileChange()
    self:RefreshStatusBarScopedModules()
end

-- ---------------------------------------------------------------------------
-- Standalone config window (FluxOptionsShell)
-- ---------------------------------------------------------------------------

local function FluxOptions_GetAddonVersionString()
    if FLUX_API and FLUX_API.addonVersion and FLUX_API.addonVersion ~= "" then
        return FLUX_API.addonVersion
    end
    local v = GetAddOnMetadata and GetAddOnMetadata(addonName, "Version")
    if (not v or v == "") and addonName ~= "_FluxUI" then
        v = GetAddOnMetadata and GetAddOnMetadata("_FluxUI", "Version")
    end
    if v and v ~= "" then
        return v
    end
    return "unknown"
end

local function FluxOptions_GetClientStatusString()
    local expansion = (FLUX_API and FLUX_API.expansion) or "Unknown"
    local clientVersion = "unknown"
    if GetBuildInfo then
        local version, build = GetBuildInfo()
        if version and build then
            clientVersion = version .. " (" .. build .. ")"
        elseif version then
            clientVersion = version
        end
    end
    return expansion .. " " .. clientVersion
end

local function FluxOptions_GetConfigStatusText()
    return string.format(
        "FluxUI: %s | Client: %s",
        FluxOptions_GetAddonVersionString(),
        FluxOptions_GetClientStatusString()
    )
end

function FluxOptions:GetConfigStatusText()
    return FluxOptions_GetConfigStatusText()
end

--- Accent on the options shell (selection bar, active tab, toggle, slider).
function FluxOptions_ApplyConfigWindowAppearance()
    local shell = ns.FluxOptionsShell
    if shell and shell.ApplyAccent then
        shell:ApplyAccent()
    end
end

local function OptionsShell()
    return ns.FluxOptionsShell
end

--- Defensive panel cleanup hook (panels clear lastActiveWidget / cancel work).
function _G.FluxOptions_OnOptionsClosed()
    if _G.FluxLayoutPreviewUI_OnOptionsClosed then
        pcall(_G.FluxLayoutPreviewUI_OnOptionsClosed)
    end
    if _G.FluxNCFlyoutPanel_OnOptionsClosed then
        pcall(_G.FluxNCFlyoutPanel_OnOptionsClosed)
    end
    if _G.FluxStanceBarOrderPanel_OnOptionsClosed then
        pcall(_G.FluxStanceBarOrderPanel_OnOptionsClosed)
    end
    if _G.FluxSpellBlacklistPanel_OnOptionsClosed then
        pcall(_G.FluxSpellBlacklistPanel_OnOptionsClosed)
    end
    if _G.FluxSpellBookSlotsPanel_OnOptionsClosed then
        pcall(_G.FluxSpellBookSlotsPanel_OnOptionsClosed)
    end
    if _G.FluxExtraButtonVisibilityPanel_OnOptionsClosed then
        pcall(_G.FluxExtraButtonVisibilityPanel_OnOptionsClosed)
    end
    if _G.FluxBindingBrowser_Detach then
        pcall(_G.FluxBindingBrowser_Detach)
    end
end

local function OpenFluxUIOptionsToGroup(...)
    local keys = { ... }
    if #keys == 0 or type(keys[1]) ~= "string" or keys[1] == "" then
        return
    end
    FluxOptions:ShowConfig(keys[1], keys[2])
end

function FluxOptions:ShowConfig(pageId, subKey)
    if not self:EnsureOptionsUI() then
        return
    end
    local shell = OptionsShell()
    if shell and shell.Show then
        shell:Show(pageId, subKey)
    end
end

function FluxOptions:ToggleConfig()
    if not self:EnsureOptionsUI() then
        return
    end
    local shell = OptionsShell()
    if not shell then
        return
    end
    if shell:IsShown() then
        self:CloseConfig()
    else
        shell:Show()
    end
end

function FluxOptions:CloseConfig()
    local shell = OptionsShell()
    if shell and shell.Hide then
        shell:Hide()
    end
end

--- Open the FluxUI options window on the MicroMenu tab (embedded layout editor).
function FluxOptions:OpenToMicroMenuTab()
    OpenFluxUIOptionsToGroup("micromenu")
end

--- Open the FluxUI options window on the Vendor & restock tab.
function FluxOptions:OpenToVendorTab()
    OpenFluxUIOptionsToGroup("vendor")
end

--- Open the FluxUI options window on the Salvage tab.
function FluxOptions:OpenToSalvageTab()
    OpenFluxUIOptionsToGroup("vendor", "salvage")
end

--- Open the FluxUI options window on the Status Bars tab (item currency, gold strip, etc.)
function FluxOptions:OpenToStatusBarsTab()
    OpenFluxUIOptionsToGroup("statusBars")
end

--- Open the FluxUI options window on the Binding browser tab.
function FluxOptions:OpenToBindingTab()
    OpenFluxUIOptionsToGroup("binding")
end

--- Open the FluxUI options window on the Party / Raid tab of Unit Frames.
function FluxOptions:OpenToRaidFrameTab()
    OpenFluxUIOptionsToGroup("unitframes", "partyRaid")
end

--- Open the FluxUI options window on the Action Bars tab.
function FluxOptions:OpenToActionBarsTab()
    OpenFluxUIOptionsToGroup("actionbars")
end

function FluxOptions:OpenToActionBarsBindingsTab()
    OpenFluxUIOptionsToGroup("actionbars", "bindings")
end

--- Open the FluxUI options window on the FluxWindow tab.
function FluxOptions:OpenToFluxWindowTab()
    OpenFluxUIOptionsToGroup("fluxwindow")
end

--- Blizzard AddOns list and /fluxui bliz both open this window.
--- Post-DF retail never registers a Settings canvas (nameplate preview taint).
function FluxOptions:OpenBlizzardOptions()
    self:ShowConfig()
end

-- ---------------------------------------------------------------------------
-- Initialization (runs on ADDON_LOADED for our addon)
-- ---------------------------------------------------------------------------
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")

local function RefreshAfterLogin()
    if FluxBorder and FluxBorder.RefreshAppearanceDependents then
        FluxBorder:RefreshAppearanceDependents()
    end
end

--- Character profile enforcement needs a valid player name; run when ready (PEW or immediately if already available).
local function ApplyLoginProfileWhenReady()
    if not FluxOptions.db or not FluxOptions:IsCharacterProfileNameReady() then
        return
    end
    FluxOptions:EnforceProfileForLogin()
    RefreshAfterLogin()
end

initFrame:SetScript("OnEvent", function(self, event, loadedAddon)
    if event == "PLAYER_ENTERING_WORLD" then
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        ApplyLoginProfileWhenReady()
        return
    end

    if event ~= "ADDON_LOADED" or loadedAddon ~= addonName then return end
    if ns.Flux and ns.Flux.optionsBootstrapComplete then return end

    if Flux and Flux.PlayerName and Flux.PlayerName.MigrateCurrentCharacterAccountData then
        Flux.PlayerName.MigrateCurrentCharacterAccountData()
    end

    -- 1. Create AceDB database
    FluxOptions.db = FluxOptions.db or AceDB:New("FluxUI_Options", FluxOptionsDefaults, true)

    -- 1b. Account-wide: enforce Default immediately (no player name needed).
    -- Character-specific: wait until player name/realm exist - early SetProfile would use "Char - Unknown - Unknown"
    -- and steal the session away from the real per-character profile (custom accent lost on reload).
    if not FluxOptions.db.char.useCharacterSpecific then
        if FluxOptions.db:GetCurrentProfile() ~= ACCOUNT_PROFILE then
            FluxOptions.db:SetProfile(ACCOUNT_PROFILE)
        end
    end

    if FluxOptions:IsCharacterProfileNameReady() then
        ApplyLoginProfileWhenReady()
    else
        self:RegisterEvent("PLAYER_ENTERING_WORLD")
    end

    -- Guard flag to suppress recursive callbacks during multi-step profile operations.
    local _profileOpGuard = false

    local function RefreshAfterProfileChange()
        if FluxBorder and FluxBorder.RefreshAppearanceDependents then
            FluxBorder:RefreshAppearanceDependents()
        elseif FluxBorder and FluxBorder.RefreshAllAccentedFrames then
            FluxBorder:RefreshAllAccentedFrames()
        end
        if not FluxOptions:IsActionbarsCharacterSpecific() then
            FluxOptions:RefreshActionbarsAfterProfileChange()
        end
        if not FluxOptions:IsRaidFramesCharacterSpecific() then
            FluxOptions:RefreshRaidFramesAfterProfileChange()
        end
        if not FluxOptions:IsUnitFramesCharacterSpecific() then
            FluxOptions:RefreshUnitFramesAfterProfileChange()
        end
        if not FluxOptions:IsStatusBarsCharacterSpecific() then
            FluxOptions:RefreshStatusBarsAfterProfileChange()
        end
        FluxOptions:RefreshLayoutScopedModulesAfterProfileChange()
        if FluxExtraButtonVisibility and FluxExtraButtonVisibility.NotifyChanged then
            FluxExtraButtonVisibility.NotifyChanged()
        end
        if FluxOptions.OnProfileChanged then
            FluxOptions:OnProfileChanged()
        end
    end

    -- OnProfileChanged: sync scope flag when the active profile switches.
    local function OnProfileChanged()
        if _profileOpGuard then return end
        local current = FluxOptions.db:GetCurrentProfile()
        local isChar = (current ~= ACCOUNT_PROFILE)
        FluxOptions.db.char.useCharacterSpecific = isChar
        FluxOptions.db.profile.settingsScope = isChar and "character" or "account"
        RefreshAfterProfileChange()
    end

    -- OnProfileCopied: if a character-scope profile was copied into Default,
    -- redirect the data into this character's own profile and clean up Default.
    local function OnProfileCopied(_, _, _, sourceProfile)
        if _profileOpGuard then return end
        local db = FluxOptions.db
        local copiedScope = db.profile.settingsScope

        if copiedScope == "character" and db:GetCurrentProfile() == ACCOUNT_PROFILE then
            if not FluxOptions:IsCharacterProfileNameReady() then
                RefreshAfterProfileChange()
                return
            end
            _profileOpGuard = true

            local charProfile = FluxOptions:GetCharacterProfileName()
            db:SetProfile(charProfile)
            if sourceProfile then
                db:CopyProfile(sourceProfile)
            end
            db.char.characterProfileInitialized = true
            db.char.useCharacterSpecific = true
            db.profile.settingsScope = "character"

            -- Undo pollution: reset Default back to defaults.
            db:SetProfile(ACCOUNT_PROFILE)
            db:ResetProfile()
            db:SetProfile(charProfile)

            _profileOpGuard = false
            RefreshAfterProfileChange()
            return
        end

        local current = db:GetCurrentProfile()
        local isChar = (current ~= ACCOUNT_PROFILE)
        db.char.useCharacterSpecific = isChar
        db.profile.settingsScope = isChar and "character" or "account"
        RefreshAfterProfileChange()
    end

    -- OnProfileReset: profile returns to defaults (settingsScope = "account").
    local function OnProfileReset()
        if _profileOpGuard then return end
        local current = FluxOptions.db:GetCurrentProfile()
        local isChar = (current ~= ACCOUNT_PROFILE)
        FluxOptions.db.char.useCharacterSpecific = isChar
        RefreshAfterProfileChange()
    end

    FluxOptions.db.RegisterCallback(FluxOptions, "OnProfileChanged", OnProfileChanged)
    FluxOptions.db.RegisterCallback(FluxOptions, "OnProfileCopied", OnProfileCopied)
    FluxOptions.db.RegisterCallback(FluxOptions, "OnProfileReset", OnProfileReset)

    -- NotifyChange("FluxUI") used to rebuild the Ace dialog. Refresh the open page instead.
    local ACR = LibStub("AceConfigRegistry-3.0", true)
    if ACR and ACR.NotifyChange and not ACR._fluxOptionsNotifyHooked then
        ACR._fluxOptionsNotifyHooked = true
        local origNotify = ACR.NotifyChange
        function ACR:NotifyChange(appName, ...)
            if appName == "FluxUI" then
                if FluxOptions.RefreshOpenPage then
                    FluxOptions:RefreshOpenPage()
                end
                return
            end
            return origNotify(self, appName, ...)
        end
    end

    -- Older clients: a one-button entry in Blizzard's AddOns list.
    -- Post-DF retail: skip — RegisterCanvasLayoutCategory under _FluxUI poisons nameplate preview.
    local skipBlizSettings = FLUX_API and FLUX_API.isRetail and FLUX_API.isPostDF
    if not skipBlizSettings and not blizzardOptionsRegistered then
        local panel = CreateFrame("Frame", "FluxUIBlizzardOptionsStub", UIParent)
        panel.name = "FluxUI"
        panel:Hide()
        local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -24)
        title:SetText("FluxUI")
        local note = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        note:SetPoint("TOP", title, "BOTTOM", 0, -8)
        note:SetWidth(420)
        note:SetText("FluxUI options open in their own window.")
        local btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        btn:SetSize(200, 26)
        btn:SetPoint("TOP", note, "BOTTOM", 0, -16)
        btn:SetText("Open FluxUI Options")
        btn:SetScript("OnClick", function()
            if SettingsPanel and SettingsPanel.Hide then
                SettingsPanel:Hide()
            end
            if InterfaceOptionsFrame and InterfaceOptionsFrame.Hide then
                InterfaceOptionsFrame:Hide()
            end
            FluxOptions:ShowConfig()
        end)
        local registered = false
        if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
            local ok, category = pcall(Settings.RegisterCanvasLayoutCategory, panel, "FluxUI")
            if ok and category then
                pcall(Settings.RegisterAddOnCategory, category)
                registered = true
            end
        end
        if not registered and InterfaceOptions_AddCategory then
            InterfaceOptions_AddCategory(panel)
            registered = true
        end
        blizzardAddonOptionsPanelFrame = panel
        blizzardOptionsRegistered = registered
    end

    -- Slash commands (EnsureOptionsUI runs inside ToggleConfig / OpenBlizzardOptions)
    SLASH_FLUXUI_OPTIONS1 = "/fluxui"
    SLASH_FLUXUI_OPTIONS2 = "/fluxoptions"
    SlashCmdList["FLUXUI_OPTIONS"] = function(msg)
        msg = (msg or ""):lower():match("^%s*(.-)%s*$")
        if msg == "bliz" or msg == "blizzard" then
            FluxOptions:OpenBlizzardOptions()
        elseif msg == "raidpreview" then
            if _G.FluxRaidPreview and _G.FluxRaidPreview.Toggle then
                _G.FluxRaidPreview.Toggle()
            end
        else
            FluxOptions:ToggleConfig()
        end
    end

    -- Expose ns reference for modules loaded after options
    ns.Options = FluxOptions
    if ns.Flux then ns.Flux.optionsBootstrapComplete = true end
    self:UnregisterEvent("ADDON_LOADED")
end)

function FluxOptions.EnsureSavedConfiguration()
    if not (ns.Flux and ns.Flux.optionsBootstrapComplete) then
        initFrame:GetScript("OnEvent")(initFrame, "ADDON_LOADED", addonName)
    end
end

-- The secure phase needs the saved profile during the kernel's ADDON_LOADED
-- transaction, before any action frame or override binding is configured.
if ns.Flux and ns.Flux.AfterLoad then
    ns.Flux.AfterLoad(FluxOptions.EnsureSavedConfiguration)
end

