-- FluxMicroMenu.lua
-- Universal Micromenu for FluxUI
-- Replacing the default Micro Menu with a custom, consistent top-left container.

local addonName, addonTable = ...
local Flux = (addonTable and addonTable.Flux) or _G.Flux
local managedStartup = Flux and Flux.Module and Flux.Module.Register
local RequestDiscoveryRefresh
local ScheduleBesideChatStayOnScreen
local isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)

--- Set in-file before `UpdateLayout`; used from `CreateMicroButton` after load.
local FluxApplyDfHudCustomMicroButtonIconLayout
local FluxApplyPreDfCustomMicroButtonIconLayout

-- Forward declaration: discovery cache cleared when new *MicroButton globals are created
local InvalidateDiscoverCacheInternal

-- ---------------------------------------------------------------------------
-- 1. Create the Container
-- ---------------------------------------------------------------------------

local FluxMicroMenu = CreateFrame("Frame", "FluxMicroMenu", UIParent)
FluxMicroMenu:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 2, 0) -- Default position Top-Left
FluxMicroMenu:SetSize(300, 40) -- Initial size, will be resized by layout
--- Minimum bar width when the layout is empty or only padding would apply (set > 0 to avoid a 1px-wide bar).
FluxMicroMenu.MIN_BAR_WIDTH = 250

-- Apply Universal Border
if FluxBorder then
    FluxBorder:ApplyTo(FluxMicroMenu)
    FluxBorder:SetClassColor(FluxMicroMenu)
    -- Lower border frame level to be below UnifiedBorder (MEDIUM level 7)
    if FluxMicroMenu.FluxBorderFrame then
        FluxMicroMenu.FluxBorderFrame:SetFrameStrata("MEDIUM")
        FluxMicroMenu.FluxBorderFrame:SetFrameLevel(6) -- Below UnifiedBorder (level 7) but above StatusBar border (BACKGROUND level 5)
    end
    FluxMicroMenu._fluxBorderMode = "default"
end

-- Create a hidden parent
local FluxHiddenParent = _G.FluxHiddenParent or CreateFrame("Frame", "FluxMicroMenuHiddenParent", UIParent)
FluxHiddenParent:Hide()

-- ---------------------------------------------------------------------------
-- 1.5 Custom Button Helper
-- ---------------------------------------------------------------------------

local function IsAtlasAvailable(name)
    if not name then return false end
    if C_Texture and C_Texture.GetAtlasInfo then
        return C_Texture.GetAtlasInfo(name)
    end
    -- Fallback/Legacy check
    if GetAtlasInfo then
        return GetAtlasInfo(name)
    end
    return false
end

--- Live and Forever use the Dragonflight HUD shell. Era and Anniversary ship the same atlas
--- files in the UI source, but their micro menu is still the 29×37 classic shell.
local function UseDfHudMicroButtonShell()
    if FluxShouldApplyMicroButtonTopGapLayout then
        local ok, on = pcall(FluxShouldApplyMicroButtonTopGapLayout)
        if ok then
            return on == true
        end
    end
    return isRetail and IsAtlasAvailable("UI-HUD-MicroMenu-ButtonBG-Up") and true or false
end

-- Classic LoadMicroButtonTextures (era, anniversary, wrath, cata, mists): one shared hilight.
local CLASSIC_MICRO_HIGHLIGHT = "Interface\\Buttons\\UI-MicroButton-Hilight"
local CLASSIC_MICRO_COORDS = { 0, 1, 0.359375, 1 }

-- Retail/Forever MainMenuBarMicroButtonMixin:SetNormal uses the per-icon -Mouseover atlas as the
-- highlight (BLEND) and hides the normal icon because the shadow is baked into that art.
-- Custom icons have no -Mouseover atlas. An ADD copy of the icon is the same brighten.
-- SetPushed drops ADD highlights to 0.50 because full ADD blows out.
local DF_MICRO_HL_ALPHA = 0.50

local function CopyTexCoord(src, dst)
    if not src or not dst or not src.GetTexCoord or not dst.SetTexCoord then
        return
    end
    local ok, a, b, c, d, e, f, g, h = pcall(src.GetTexCoord, src)
    if not ok or a == nil then
        return
    end
    if e ~= nil then
        pcall(dst.SetTexCoord, dst, a, b, c, d, e, f, g, h)
    else
        pcall(dst.SetTexCoord, dst, a, b, c, d)
    end
end

local function BindMicroHighlightMask(btn, hl)
    if not btn or not hl or hl._fluxMaskBound then
        return
    end
    local mask = btn._fluxPortraitMask
    if mask and hl.AddMaskTexture then
        pcall(hl.AddMaskTexture, hl, mask)
        hl._fluxMaskBound = true
    end
end

local function SyncDfIconHighlight(btn)
    if not btn or btn._fluxSyncingHighlight then
        return
    end
    local icon = btn.icon
    local hl = btn._fluxMicroHighlight
    local source = btn._fluxPortraitSource or btn.Portrait or icon
    if btn._fluxPlayerPortrait and source and btn._fluxPortraitGlow then
        btn._fluxSyncingHighlight = true
        local host = btn._fluxPortraitGlow
        local glow = host._tex
        if glow and SetPortraitTexture then
            glow._fluxIsMicroHighlight = true
            pcall(SetPortraitTexture, glow, "player")
            CopyTexCoord(source, glow)
            if glow.SetBlendMode then
                glow:SetBlendMode("ADD")
            end
            if glow.SetAlpha then
                glow:SetAlpha(DF_MICRO_HL_ALPHA)
            end
        end
        if host.ClearAllPoints and host.SetAllPoints then
            host:ClearAllPoints()
            host:SetAllPoints(source)
        end
        btn._fluxSyncingHighlight = false
        return
    end
    if not hl or not source then
        return
    end
    btn._fluxSyncingHighlight = true
    if not icon then
        btn._fluxSyncingHighlight = false
        return
    end
    local atlas
    if icon.GetAtlas then
        local ok, name = pcall(icon.GetAtlas, icon)
        if ok and type(name) == "string" and name ~= "" then
            atlas = name
        end
    end
    if atlas and hl.SetAtlas then
        -- GetTexCoord after SetAtlas is often the whole atlas page. Leave the atlas UVs alone.
        pcall(hl.SetAtlas, hl, atlas, false)
    else
        local tex
        if icon.GetTexture then
            local ok, value = pcall(icon.GetTexture, icon)
            if ok and value ~= nil and value ~= "" then
                tex = value
            end
        end
        if tex ~= nil and hl.SetTexture then
            pcall(hl.SetTexture, hl, tex)
            CopyTexCoord(icon, hl)
        end
    end
    if hl.ClearAllPoints and hl.SetAllPoints then
        hl:ClearAllPoints()
        hl:SetAllPoints(icon)
    end
    if hl.SetBlendMode then
        hl:SetBlendMode("ADD")
    end
    if hl.SetAlpha then
        hl:SetAlpha(DF_MICRO_HL_ALPHA)
    end
    BindMicroHighlightMask(btn, hl)
    btn._fluxSyncingHighlight = false
end

local function WatchDfIconHighlight(btn)
    local icon = btn and btn.icon
    if not icon or icon._fluxHighlightWatch or not hooksecurefunc then
        return
    end
    icon._fluxHighlightWatch = true
    local function sync()
        SyncDfIconHighlight(btn)
    end
    hooksecurefunc(icon, "SetTexture", sync)
    hooksecurefunc(icon, "SetTexCoord", sync)
    if icon.SetAtlas then
        hooksecurefunc(icon, "SetAtlas", sync)
    end
end

--- Dragonflight HUD (live + Forever): hover brightens the custom icon the way -Mouseover art does.
local function ApplyDfCustomMicroMouseover(btn)
    if not btn or not btn.icon or not btn.SetHighlightTexture then
        return
    end
    if not btn._fluxMicroHighlight then
        -- Pass a file, not an atlas texture. SetHighlightTexture drops atlas objects.
        btn:SetHighlightTexture("Interface\\Icons\\INV_Misc_QuestionMark", "ADD")
        local hl = btn.GetHighlightTexture and btn:GetHighlightTexture()
        if not hl then
            return
        end
        btn._fluxMicroHighlight = hl
        btn._fluxConfigHighlight = hl
        btn._fluxDfIconHighlight = true
    end
    WatchDfIconHighlight(btn)
    -- HookScript on a protected micro button taints its secure click. The highlight
    -- texture still shows on its own; texture hooks keep the art in sync.
    local protected = btn.IsProtected and btn:IsProtected()
    if not protected and not btn._fluxDfHighlightHooked and btn.HookScript then
        btn._fluxDfHighlightHooked = true
        btn:HookScript("OnEnter", function(self)
            SyncDfIconHighlight(self)
        end)
    end
    SyncDfIconHighlight(btn)
end

--- Classic shell (era, anniversary, and any client still on UI-MicroButton-* art).
local function ApplyClassicCustomMicroMouseover(btn)
    if not btn or not btn.SetHighlightTexture then
        return
    end
    btn:SetHighlightTexture(CLASSIC_MICRO_HIGHLIGHT, "ADD")
    local hl = btn.GetHighlightTexture and btn:GetHighlightTexture()
    if not hl then
        return
    end
    if hl.SetBlendMode then
        hl:SetBlendMode("ADD")
    end
    hl:SetTexCoord(CLASSIC_MICRO_COORDS[1], CLASSIC_MICRO_COORDS[2], CLASSIC_MICRO_COORDS[3], CLASSIC_MICRO_COORDS[4])
    if hl.SetAlpha then
        hl:SetAlpha(1)
    end
    btn._fluxMicroHighlight = hl
    btn._fluxConfigHighlight = hl
    btn._fluxDfIconHighlight = nil
end

function FluxMicroMenu:ApplyCustomMicroMouseover(btn, kind)
    if kind == "df" then
        ApplyDfCustomMicroMouseover(btn)
    else
        ApplyClassicCustomMicroMouseover(btn)
    end
end

function _G.FluxApplyCustomMicroMouseover(btn, kind)
    return FluxMicroMenu:ApplyCustomMicroMouseover(btn, kind)
end

local function ShowCharacterPortraitGlow(btn)
    local host = btn and btn._fluxPortraitGlow
    if not host then
        return
    end
    local level = (btn.GetFrameLevel and btn:GetFrameLevel()) or 0
    if host.SetFrameStrata and btn.GetFrameStrata then
        host:SetFrameStrata(btn:GetFrameStrata())
    end
    if host.SetFrameLevel then
        host:SetFrameLevel(level + 20)
    end
    local source = btn._fluxPortraitSource or btn.Portrait or btn.icon
    if source and host.SetAllPoints then
        host:ClearAllPoints()
        host:SetAllPoints(source)
    end
    host:Show()
end

local function HideCharacterPortraitGlow(btn)
    local host = btn and btn._fluxPortraitGlow
    if host then
        host:Hide()
    end
end

function _G.FluxShowCharacterPortraitGlow(btn)
    ShowCharacterPortraitGlow(btn)
end

function _G.FluxHideCharacterPortraitGlow(btn)
    HideCharacterPortraitGlow(btn)
end

--- The character face is a live portrait. The button highlight slot draws under that
--- portrait (and the portrait mask blanks an ADD texture), so hover never appears.
--- A child frame above the face is shown from OnEnter instead.
local function ApplyCharacterPortraitMouseover(btn, portrait)
    if not btn or not UseDfHudMicroButtonShell() then
        return
    end
    portrait = portrait or btn._fluxPortraitSource or btn.Portrait or btn.icon or _G.MicroButtonPortrait
    if not portrait then
        return
    end
    btn._fluxPlayerPortrait = true
    btn._fluxPortraitSource = portrait
    -- Drop the highlight-slot copy. It stays hidden under the face.
    local slot = btn._fluxMicroHighlight
    if slot and slot.SetAlpha and btn._fluxDfIconHighlight then
        slot:SetAlpha(0)
    end
    local host = btn._fluxPortraitGlow
    if not host then
        host = CreateFrame("Frame", nil, btn)
        host:EnableMouse(false)
        host:Hide()
        local glow = host:CreateTexture(nil, "OVERLAY")
        glow:SetAllPoints()
        glow:SetBlendMode("ADD")
        glow:SetAlpha(DF_MICRO_HL_ALPHA)
        glow._fluxIsMicroHighlight = true
        host._tex = glow
        btn._fluxPortraitGlow = host
        if not btn._fluxPortraitGlowHooked then
            btn._fluxPortraitGlowHooked = true
            -- HookScript on CharacterMicroButton taints Click() from the secure
            -- proxy. CharacterFrame:OnShow then compares secret health and throws.
            -- The mixin method post-hook leaves OnClick untainted.
            local client = _G.Flux and _G.Flux.Client
            local camelot = client and client.isCamelot
            local protected = btn.IsProtected and btn:IsProtected()
            if type(hooksecurefunc) == "function" and type(btn.OnEnter) == "function" and type(btn.OnLeave) == "function" then
                hooksecurefunc(btn, "OnEnter", ShowCharacterPortraitGlow)
                hooksecurefunc(btn, "OnLeave", HideCharacterPortraitGlow)
            elseif not camelot and not protected and btn.HookScript then
                btn:HookScript("OnEnter", function(self)
                    ShowCharacterPortraitGlow(self)
                end)
                btn:HookScript("OnLeave", function(self)
                    HideCharacterPortraitGlow(self)
                end)
            end
        end
    end
    SyncDfIconHighlight(btn)
    if btn.IsMouseOver and btn:IsMouseOver() then
        ShowCharacterPortraitGlow(btn)
    end
end

function FluxMicroMenu:ApplyCharacterPortraitMouseover(btn, portrait)
    ApplyCharacterPortraitMouseover(btn, portrait)
end

function _G.FluxApplyCharacterPortraitMouseover(btn, portrait)
    ApplyCharacterPortraitMouseover(btn, portrait)
end

local function FluxRefreshCharacterMicroMouseover()
    local btn = _G.CharacterMicroButton
    if not btn then
        return
    end
    ApplyCharacterPortraitMouseover(btn, btn.Portrait or _G.MicroButtonPortrait)
end

local function MicroMenuOutfitFlyoutDirection()
    local pos = 2
    if FluxOptions and FluxOptions.GetMicroMenuLayoutPosition then
        local layoutPos = FluxOptions:GetMicroMenuLayoutPosition()
        if type(layoutPos) == "number" then
            pos = layoutPos
        end
    end
    if pos == 1 then
        return "DOWN"
    end
    if pos == 3 then
        return "LEFT"
    end
    return "RIGHT"
end

--- Right-click overlay only. Left click stays on Blizzard's CharacterMicroButton handler.
local function EnsureCharacterOutfitRightClick()
    local api = addonTable and addonTable.API
    if not api or not api.HasPlayerTransmogOutfitAPI or api.HasPlayerTransmogOutfitAPI() ~= true then
        return
    end
    local btn = _G.CharacterMicroButton
    if not btn then
        return
    end
    local overlay = btn._fluxOutfitRightClick
    if not overlay then
        overlay = CreateFrame("Button", "FluxCharacterMicroOutfitClick", btn)
        overlay:SetAllPoints(btn)
        overlay:RegisterForClicks("RightButtonUp")
        if overlay.SetPassThroughButtons then
            overlay:SetPassThroughButtons("LeftButton", "MiddleButton", "Button4", "Button5")
        end
        if overlay.SetPropagateMouseMotion then
            overlay:SetPropagateMouseMotion(true)
        end
        overlay:EnableMouse(true)
        overlay:SetScript("OnClick", function(_, button)
            if button ~= "RightButton" then
                return
            end
            local ptc = addonTable.PlayerTransmogClick
            if ptc and ptc.ToggleOutfitFlyout then
                ptc.ToggleOutfitFlyout(btn, MicroMenuOutfitFlyoutDirection())
            end
            if GameTooltip then
                GameTooltip:Hide()
            end
        end)
        btn._fluxOutfitRightClick = overlay
    end
    if overlay.SetFrameLevel then
        overlay:SetFrameLevel((btn:GetFrameLevel() or 0) + 5)
    end
    overlay:Show()
end

-- CharacterFrame:OnShow calls SetPortraitTexture before it compares secret health.
-- A post-hook there taints that compare. Forever refreshes the glow from events.
local camelotPortrait = _G.Flux and _G.Flux.Client and _G.Flux.Client.isCamelot
if camelotPortrait and not FluxMicroMenu._fluxPortraitMouseoverHook then
    FluxMicroMenu._fluxPortraitMouseoverHook = true
    local watch = CreateFrame("Frame")
    watch:RegisterEvent("UNIT_PORTRAIT_UPDATE")
    watch:RegisterEvent("PORTRAITS_UPDATED")
    watch:RegisterEvent("PLAYER_ENTERING_WORLD")
    watch:SetScript("OnEvent", function(_, event, unit)
        if event == "UNIT_PORTRAIT_UPDATE" and unit ~= "player" then
            return
        end
        FluxRefreshCharacterMicroMouseover()
    end)
elseif hooksecurefunc and SetPortraitTexture and not FluxMicroMenu._fluxPortraitMouseoverHook then
    FluxMicroMenu._fluxPortraitMouseoverHook = true
    hooksecurefunc("SetPortraitTexture", function(texture, unit)
        if unit ~= "player" or not texture or texture._fluxIsMicroHighlight then
            return
        end
        local btn = texture.GetParent and texture:GetParent()
        if not btn then
            return
        end
        if btn._fluxPlayerPortrait and btn._fluxPortraitGlow and texture ~= btn._fluxPortraitGlow._tex then
            SyncDfIconHighlight(btn)
            return
        end
        if btn.GetName and btn:GetName() == "CharacterMicroButton" then
            ApplyCharacterPortraitMouseover(btn, texture)
        end
    end)
end

-- Global accessible helper
function FluxMicroMenu:CreateMicroButton(globalName, iconTexture, tooltipTitle, bindingToken, clickHandler)
    if not _G[globalName] then
        -- 1. Create Frame with appropriate template support
        local btn = CreateFrame("Button", globalName, UIParent, BackDropTemplateMixin and "BackdropTemplate" or nil)
        
        -- 2. Apply Custom Styling based on Client Version
        -- Live/Forever HUD shell. Era and Anniversary stay on the classic 29×37 shell.
        if UseDfHudMicroButtonShell() then
            -- [RETAIL / DRAGONFLIGHT+ STYLE]
            -- Native Spec: 32x40, uses UI-HUD-MicroMenu-ButtonBG-Up/Down atlases
            btn:SetSize(32, 40)
            
            -- Background (The 'shell')
            local bg = btn:CreateTexture(nil, "BACKGROUND")
            bg:SetAtlas("UI-HUD-MicroMenu-ButtonBG-Up", true)
            bg:SetPoint("CENTER")
            
            local pushedBg = btn:CreateTexture(nil, "BACKGROUND")
            pushedBg:SetAtlas("UI-HUD-MicroMenu-ButtonBG-Down", true)
            pushedBg:SetPoint("CENTER")
            pushedBg:Hide()
            
            btn:SetScript("OnMouseDown", function()
                bg:Hide()
                pushedBg:Show()
                if FluxApplyDfHudCustomMicroButtonIconLayout then
                    FluxApplyDfHudCustomMicroButtonIconLayout(btn, true)
                elseif btn.icon then
                    btn.icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -6, 6)
                    btn.icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 8, -8)
                end
            end)
            btn:SetScript("OnMouseUp", function()
                bg:Show()
                pushedBg:Hide()
                if FluxApplyDfHudCustomMicroButtonIconLayout then
                    FluxApplyDfHudCustomMicroButtonIconLayout(btn, false)
                elseif btn.icon then
                    btn.icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -7, 7)
                    btn.icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 7, -7)
                end
            end)

            -- Icon (Correctly inset like 'Portrait' in CharacterMicroButton)
            local icon = btn:CreateTexture(nil, "ARTWORK")
            icon:SetTexture(iconTexture)
            icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 7, -7)
            icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -7, 7)
            -- Use native portrait TexCoords
            icon:SetTexCoord(0.2, 0.8, 0.0666, 0.9)
            btn.icon = icon
            ApplyDfCustomMicroMouseover(btn)

            if FluxApplyDfHudCustomMicroButtonIconLayout then
                FluxApplyDfHudCustomMicroButtonIconLayout(btn, false)
            end

        else
            -- [CLASSIC / PRE-DF STYLE]
            -- Native Spec: 28x36 (Standard size often used by mods or derived from 29x37)
            -- Blizzard Source "MainMenuBarMicroButton" XML says 29x37.
            btn:SetSize(29, 37)
            
            -- Background Textures (The button shell)
            -- Blizzard's 'LoadMicroButtonTextures' sets these specific coords: { 0, 1, 0.359375, 1 }
            local texCoords = { 0, 1, 0.359375, 1 }

            btn:SetNormalTexture("Interface\\Buttons\\UI-MicroButtonCharacter-Up")
            btn:SetPushedTexture("Interface\\Buttons\\UI-MicroButtonCharacter-Down")
            ApplyClassicCustomMicroMouseover(btn)
            
            local normal = btn:GetNormalTexture()
            if normal then 
                normal:SetTexCoord(unpack(texCoords)) 
            end
            
            local pushed = btn:GetPushedTexture()
            if pushed then 
                pushed:SetTexCoord(unpack(texCoords)) 
                pushed:SetPoint("TOPLEFT", 0, 0)
            end

            -- Icon Overlay
            -- Native Spec: Size 18x25, Anchor CENTER 0, -1, TexCoords 0.2, 0.8, 0.0666, 0.9
            local icon = btn:CreateTexture(nil, "OVERLAY")
            icon:SetTexture(iconTexture)
            icon:SetSize(18, 25)
            icon:SetPoint("CENTER", btn, "CENTER", 0, -1)
            icon:SetTexCoord(0.2, 0.8, 0.0666, 0.9)
            btn.icon = icon
            
            -- Pushed effect
            btn:SetScript("OnMouseDown", function()
                if FluxApplyPreDfCustomMicroButtonIconLayout then
                    FluxApplyPreDfCustomMicroButtonIconLayout(btn, true)
                elseif btn.icon then
                    btn.icon:SetPoint("CENTER", btn, "CENTER", 0, -2)
                end
                if btn.icon then
                    btn.icon:SetVertexColor(0.8, 0.8, 0.8)
                end
            end)
            btn:SetScript("OnMouseUp", function()
                if FluxApplyPreDfCustomMicroButtonIconLayout then
                    FluxApplyPreDfCustomMicroButtonIconLayout(btn, false)
                elseif btn.icon then
                    btn.icon:SetPoint("CENTER", btn, "CENTER", 0, -1)
                end
                if btn.icon then
                    btn.icon:SetVertexColor(1, 1, 1)
                end
            end)

            if FluxApplyPreDfCustomMicroButtonIconLayout then
                FluxApplyPreDfCustomMicroButtonIconLayout(btn, false)
            end
        end


        -- 3. Common Logic (Tooltip & Click)
        
        -- Set Tooltip Scripts
        btn:SetScript("OnEnter", function(self)
            if GameTooltip then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(tooltipTitle)
                if bindingToken and GetBindingKey then
                     local key = GetBindingKey(bindingToken)
                     if key then
                         GameTooltip:AddLine("Key: " .. key, 1, 1, 1)
                     end
                end
                
                -- Dynamic tooltip extension (can be overridden by caller before this hook if needed, 
                -- or caller can hook OnEnter themselves)
                -- Dynamic tooltip extension
                if clickHandler and type(clickHandler) == "table" and clickHandler.OnTooltip then
                     clickHandler.OnTooltip(GameTooltip)
                end
                
                GameTooltip:Show()
            end
        end)
        
        btn:SetScript("OnLeave", function(self)
            if GameTooltip then GameTooltip:Hide() end
        end)

        -- Click Handler with Sound
        btn:HookScript("OnClick", function(self, button, down)
            -- Play standard button sound
            if PlaySound then
                PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or "igMainMenuOptionCheckBoxOn")
            end
            if clickHandler then 
                if type(clickHandler) == "function" then
                    clickHandler(self, button, down) 
                elseif type(clickHandler) == "table" and clickHandler.OnClick then
                    clickHandler.OnClick(self, button, down)
                end
            end
        end)

        if InvalidateDiscoverCacheInternal then
            InvalidateDiscoverCacheInternal()
        end
        if RequestDiscoveryRefresh then RequestDiscoveryRefresh() end
        return btn
    end
end

--- Config preview: draw one static frame — SetAtlas can animate HUD atlases; prefer file + fixed texcoords.
--- On DF+, live icons use SetAtlas; GetTexture+texCoords often resolves to the whole atlas page + 0–1 UV — prefer atlas name when present.
local function ApplyConfigPreviewIconLayer(icon, iconTexture, texPath, atlasName)
    local tbl = type(iconTexture) == "table" and iconTexture or nil
    if tbl and tbl.usePlayerPortrait and SetPortraitTexture then
        pcall(SetPortraitTexture, icon, "player")
        return
    end
    local coords = tbl and tbl.texCoords
    local tex = tbl and (tbl.texture or texPath) or texPath
    local name = (atlasName and atlasName ~= "") and atlasName or (tbl and tbl.atlas)

    -- 1) Atlas first (matches HUD micro icons on retail; beats misleading file+full-UV snapshots)
    if name and name ~= "" then
        if C_Texture and C_Texture.GetAtlasInfo then
            local info = C_Texture.GetAtlasInfo(name)
            if info then
                local file = info.file or info.filename
                if file and info.leftTexCoord and info.rightTexCoord and info.topTexCoord and info.bottomTexCoord then
                    icon:SetTexture(file)
                    icon:SetTexCoord(info.leftTexCoord, info.rightTexCoord, info.topTexCoord, info.bottomTexCoord)
                    return
                end
            end
        end
        if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name) then
            icon:SetAtlas(name, false)
            return
        end
    end

    -- 2) Explicit texture + UV snapshot (pre-DF or non-atlas icons)
    if coords and type(coords) == "table" and coords[1] and coords[2] and coords[3] and coords[4] then
        icon:SetTexture(tex)
        if coords[5] == nil then
            icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
        else
            icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4], coords[5], coords[6], coords[7], coords[8])
        end
        return
    end

    icon:SetTexture(texPath)
    icon:SetTexCoord(0.2, 0.8, 0.0666, 0.9)
end

--- Preview-only micro button for the layout editor: same shell as CreateMicroButton, parented under config content (not registered on UIParent).
--- iconTexture: string path/fileID, or table { texture=, atlas=, texCoords= } to match live micro buttons (atlas icons).
function FluxMicroMenu:CreateConfigPreviewMicroButton(parent, iconTexture)
    if not parent then return nil end
    local texPath = "Interface\\Icons\\INV_Misc_QuestionMark"
    local atlasName = nil
    if type(iconTexture) == "table" then
        atlasName = iconTexture.atlas
        if not iconTexture.usePlayerPortrait then
            texPath = iconTexture.texture or texPath
        end
    elseif type(iconTexture) == "string" and iconTexture ~= "" then
        texPath = iconTexture
    elseif type(iconTexture) == "number" then
        texPath = iconTexture
    end
    local btn = CreateFrame("Button", nil, parent, BackDropTemplateMixin and "BackdropTemplate" or nil)

    if UseDfHudMicroButtonShell() then
        btn:SetSize(32, 40)

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAtlas("UI-HUD-MicroMenu-ButtonBG-Up", true)
        bg:SetPoint("CENTER")

        local pushedBg = btn:CreateTexture(nil, "BACKGROUND")
        pushedBg:SetAtlas("UI-HUD-MicroMenu-ButtonBG-Down", true)
        pushedBg:SetPoint("CENTER")
        pushedBg:Hide()

        btn:SetScript("OnMouseDown", function()
            bg:Hide()
            pushedBg:Show()
            if btn.icon then
                btn.icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -6, 6)
                btn.icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 8, -8)
            end
        end)
        btn:SetScript("OnMouseUp", function()
            bg:Show()
            pushedBg:Hide()
            if btn.icon then
                btn.icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -7, 7)
                btn.icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 7, -7)
            end
        end)

        local icon = btn:CreateTexture(nil, "ARTWORK")
        ApplyConfigPreviewIconLayer(icon, iconTexture, texPath, atlasName)
        icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 7, -7)
        icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -7, 7)
        btn.icon = icon
        ApplyDfCustomMicroMouseover(btn)
    else
        btn:SetSize(29, 37)
        local texCoords = { 0, 1, 0.359375, 1 }

        btn:SetNormalTexture("Interface\\Buttons\\UI-MicroButtonCharacter-Up")
        btn:SetPushedTexture("Interface\\Buttons\\UI-MicroButtonCharacter-Down")
        ApplyClassicCustomMicroMouseover(btn)

        local normal = btn:GetNormalTexture()
        if normal then
            normal:SetTexCoord(unpack(texCoords))
        end
        local pushed = btn:GetPushedTexture()
        if pushed then
            pushed:SetTexCoord(unpack(texCoords))
            pushed:SetPoint("TOPLEFT", 0, 0)
        end

        local icon = btn:CreateTexture(nil, "OVERLAY")
        ApplyConfigPreviewIconLayer(icon, iconTexture, texPath, atlasName)
        icon:SetSize(18, 25)
        icon:SetPoint("CENTER", btn, "CENTER", 0, -1)
        btn.icon = icon

        btn:SetScript("OnMouseDown", function()
            if btn.icon then
                btn.icon:SetPoint("CENTER", btn, "CENTER", 0, -2)
                btn.icon:SetVertexColor(0.8, 0.8, 0.8)
            end
        end)
        btn:SetScript("OnMouseUp", function()
            if btn.icon then
                btn.icon:SetPoint("CENTER", btn, "CENTER", 0, -1)
                btn.icon:SetVertexColor(1, 1, 1)
            end
        end)
    end

    btn:EnableMouse(true)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    if FluxStandardizeMicroButton then
        pcall(FluxStandardizeMicroButton, btn)
    end
    return btn
end

-- ---------------------------------------------------------------------------
-- 2. Configuration & Priorities
-- ---------------------------------------------------------------------------

-- Priorities for sorting (Lower = Left/First)
local BUTTON_PRIORITIES = {
    -- Flux first: Reload, then FluxUI Options, then Blizzard micro row.
    ["FluxReloadMicroButton"]       = 0,
    ["FluxConfigMicroButton"]       = 0.5, -- FluxUI Options after Reload, before Game Menu. Off by default.
    ["MainMenuMicroButton"]         = 1,
    ["CharacterMicroButton"]        = 2,
    ["SpellbookMicroButton"]        = 3,
    ["PlayerSpellsMicroButton"]     = 4,
    ["TalentMicroButton"]           = 5,
    ["LegacyMicroButton"]           = 5.5, -- Forever adventure/legacy tree
    ["SpecializationMicroButton"]   = 6,
    ["ProfessionMicroButton"]       = 7,
    ["AchievementMicroButton"]      = 8,
    ["QuestLogMicroButton"]         = 9,
    ["GuildMicroButton"]            = 10,
    ["GuildAndCommunitiesMicroButton"] = 11,
    ["CommunitiesMicroButton"]      = 12,
    -- WorldMapMicroButton is HIDDEN now
    ["LFDMicroButton"]              = 14,
    ["LFGMicroButton"]              = 14,
    ["SearchLFGButton"]             = 14,
    ["EJMicroButton"]               = 15, -- Adventure Guide
    ["CollectionsMicroButton"]      = 16,
    ["PVPMicroButton"]              = 17,

    -- Custom tail (after Blizzard row): LFG before macro, then bags, trade skills, then addons (+)
    ["FluxLFGMicroButton"]          = 90,
    ["FluxMacroMicroButton"]        = 91,
    ["FluxBagMicroButton"]          = 92,
    ["FluxTradeSkillFlyoutMicroButton"] = 92.4,
    ["FluxAddonMicroButton"]        = 93,
}

-- Expose globally so FluxMinimapToMicro can add dynamic priorities
_G.BUTTON_PRIORITIES = BUTTON_PRIORITIES

--- Fixed left-to-right default for unified native rowIds (not discovery order).
--- M2M: rows are appended by FluxMicroMenuConfig; unknown *MicroButton frames append after this list.
local DEFAULT_UNIFIED_NATIVE_ROW_ORDER = {
    "FluxReloadMicroButton",
    "FluxConfigMicroButton",
    "MainMenuMicroButton",
    "CharacterMicroButton",
    "PlayerSpellsMicroButton",
    "SpellbookMicroButton",
    "TalentMicroButton",
    "LegacyMicroButton",
    "SpecializationMicroButton",
    "ProfessionMicroButton",
    "AchievementMicroButton",
    "QuestLogMicroButton",
    "GuildMicroButton",
    "GuildAndCommunitiesMicroButton",
    "CommunitiesMicroButton",
    "LFDMicroButton",
    "LFGMicroButton",
    "SearchLFGButton",
    "EJMicroButton",
    "CollectionsMicroButton",
    "PVPMicroButton",
    "FluxLFGMicroButton",
    "FluxMacroMicroButton",
    "FluxBagMicroButton",
    "FluxAddonMicroButton",
}

-- Forever GameMenuFrame:OnShow calls UpdateMicroButtons, which Show()s StoreMicroButton.
-- Hiding or reparenting it first makes that Show run OnShow -> MicroMenuContainer:Layout().
-- Layout then reads a child list tainted by our SetParent and the rest of the menu,
-- including SetPreferredGamepadInteractTarget(), is ADDON_ACTION_FORBIDDEN.
-- Leave Store's shown flag alone (it is moved off-screen instead).
function FluxMicroMenu:ShouldLeaveBlizzardButtonShown(name)
    if name ~= "StoreMicroButton" then
        return false
    end
    return (FLUX_API and (FLUX_API.isCamelot or FLUX_API.isForever)) and true or false
end

-- Buttons to explicitly HIDE (Removed from UI entirely)
local BUTTONS_TO_HIDE = {
    ["StoreMicroButton"]            = true, 
    ["HelpMicroButton"]             = true,
    ["ShopMicroButton"]             = true,
    ["MainMenuBarDownload"]         = false, -- UNHIDE: Might be Game Menu related
    ["WorldMapMicroButton"]         = true,  -- Hidden as per request
    ["DraftModeMicroButton"]        = true,
    -- Default Bag Buttons (We use our own, but need these available for the Right-Click Window)
    ["MainMenuBarBackpackButton"]   = false,
    ["CharacterBag0Slot"]           = false,
    ["CharacterBag1Slot"]           = false,
    ["CharacterBag2Slot"]           = false,
    ["CharacterBag3Slot"]           = false,
    ["CharacterReagentBag0Slot"]    = false,
    ["BagBarExpandToggle"]          = true, -- Expand toggle we can hide
}

-- Buttons to IGNORE (Leave them exactly where they are)
local BUTTONS_TO_IGNORE = {
    ["SocialsMicroButton"]          = true,
    ["FriendsMicroButton"]          = true, -- Usually same as Socials, specific ID
}

-- ---------------------------------------------------------------------------
-- 2.1 Helpers
-- ---------------------------------------------------------------------------

local FluxHiddenParent = CreateFrame("Frame", "FluxHiddenParent", UIParent)
FluxHiddenParent:Hide()

local function DisableBlizzardLayout()
    -- Taint Guard: Do not touch UI frames during combat
    if InCombatLockdown() then 
        FluxMicroMenu.needsUpdate = true
        return 
    end

    -- This handles hiding the buttons in the list above
    for name, shouldHide in pairs(BUTTONS_TO_HIDE) do
        if shouldHide and FluxMicroMenu:ShouldLeaveBlizzardButtonShown(name) then
             local btn = _G[name]
             if btn then
                 -- Keep the shown flag Blizzard set. Moving it off-screen avoids a click
                 -- target without Hide/SetParent, which would make the next Show() run OnShow.
                 btn:ClearAllPoints()
                 btn:SetPoint("TOPLEFT", UIParent, "BOTTOMRIGHT", 200, 0)
                 if btn.EnableMouse then
                     btn:EnableMouse(false)
                 end
             end
        elseif shouldHide then
             local btn = _G[name]
             if btn then
                 btn:SetParent(FluxHiddenParent)
                 btn:Hide()
                 -- Hook OnShow to force hide if something tries to show it (e.g. changing zones/specs)
                 if not btn.FluxHideHooked then
                     btn:HookScript("OnShow", function(self) 
                        if not InCombatLockdown() then
                            self:Hide() 
                        end
                     end)
                     btn.FluxHideHooked = true
                 end
             end
        end
    end
    
    -- Disable the main MicroMenu SAFELY (Visual Hide only)
    -- Do NOT overwrite .Layout as it taints EditMode
    -- Do not SetParent/Hide/EnableMouse Edit Mode systems: InitSystemAnchors then
    -- MainActionBar:SetPointBase is ADDON_ACTION_BLOCKED on spec/level.
    if MicroMenu then
        MicroMenu:UnregisterAllEvents()
        if not InCombatLockdown() and MicroMenu.SetAlpha then
            MicroMenu:SetAlpha(0)
        end
    end
    
    if MicroMenuContainer then
        MicroMenuContainer:UnregisterAllEvents()
        if not InCombatLockdown() and MicroMenuContainer.SetAlpha then
            MicroMenuContainer:SetAlpha(0)
        end
    end
end

-- ---------------------------------------------------------------------------
-- 3. Dynamic Discovery
-- ---------------------------------------------------------------------------

-- pairs(_G) is expensive; reuse results until next frame (or explicit invalidation).
local discoverInfosCache = nil
local discoverCacheClearPending = false

local function ScheduleDiscoverCacheClear()
    if discoverCacheClearPending then return end
    discoverCacheClearPending = true
    C_Timer.After(0, function()
        discoverCacheClearPending = false
        discoverInfosCache = nil
    end)
end

InvalidateDiscoverCacheInternal = function()
    discoverInfosCache = nil
    discoverCacheClearPending = false
end

function FluxMicroMenu:InvalidateDiscoverCache()
    InvalidateDiscoverCacheInternal()
end

local function GetButtonPriority(name, btn)
    if BUTTON_PRIORITIES[name] then
        return BUTTON_PRIORITIES[name]
    end
    return 100
end

local function DiscoverButtonInfos()
    if discoverInfosCache then
        return discoverInfosCache
    end
    local found = {}
    local seen = {}

    for name, obj in pairs(_G) do
        if type(name) == "string" and string.match(name, "MicroButton$") then
            if type(obj) == "table" and obj.IsObjectType and obj:IsObjectType("Frame") then
                if not BUTTONS_TO_HIDE[name] and not BUTTONS_TO_IGNORE[name] then
                    if not seen[obj] then
                        table.insert(found, { name = name, btn = obj, prio = GetButtonPriority(name, obj) })
                        seen[obj] = true
                    end
                end
            end
        end
    end

    table.sort(found, function(a, b)
        if a.prio ~= b.prio then
            return a.prio < b.prio
        else
            return a.name < b.name
        end
    end)

    discoverInfosCache = found
    ScheduleDiscoverCacheClear()
    return found
end

local function DiscoverButtons()
    local objects = {}
    for _, info in ipairs(DiscoverButtonInfos()) do
        table.insert(objects, info.btn)
    end
    return objects
end

function FluxMicroMenu:GetDiscoveredMicroButtonNames()
    local names = {}
    for _, info in ipairs(DiscoverButtonInfos()) do
        table.insert(names, info.name)
    end
    return names
end

--- FluxUI-created *MicroButton globals may not exist on first tick; Blizzard names must exist as frames or they are excluded.
local function IsFluxCustomMicroButtonName(name)
    if type(name) ~= "string" or name == "" then return false end
    if name:sub(1, 4) ~= "Flux" then return false end
    return name:match("MicroButton$") ~= nil
end

--- Micro Menu size slider applies only to these (pre-DF); post-DF all buttons still scale, but icon insets are fixed for Flux custom.
local function IsFluxUserScalableMicroButton(btn)
    if not btn or not btn.GetName then
        return false
    end
    return IsFluxCustomMicroButtonName(btn:GetName() or "")
end

--- Client has a functional Blizzard micromenu group/dungeon finder row (hide redundant FluxLFGMicroButton).
function FluxMicroMenu:HasBlizzardGroupFinderMicroButton()
    if FLUX_API and FLUX_API.ClientHasBlizzardMicroGroupFinder then
        return FLUX_API.ClientHasBlizzardMicroGroupFinder()
    end
    if FluxClientHasBlizzardMicroGroupFinder then
        return FluxClientHasBlizzardMicroGroupFinder()
    end
    return false
end

local function ClientHasMicroMenuFeature(rowId)
    if FLUX_API and FLUX_API.ClientHasMicroMenuFeature then
        return FLUX_API.ClientHasMicroMenuFeature(rowId)
    end
    if FluxClientHasMicroMenuFeature then
        return FluxClientHasMicroMenuFeature(rowId)
    end
    return true
end

local function ClientHasMinimapGroupFinder()
    if FLUX_API and FLUX_API.ClientHasMinimapGroupFinder then
        return FLUX_API.ClientHasMinimapGroupFinder()
    end
    if FluxClientHasMinimapGroupFinder then
        return FluxClientHasMinimapGroupFinder()
    end
    return false
end

--- True if this native rowId may appear on this client: M2M rows, existing _G frame, or Flux custom micro (loads with addon).
function FluxMicroMenu:IsNativeRowAvailableOnClient(rowId)
    if type(rowId) ~= "string" or rowId == "" then return false end
    if FluxMicroMenuConfig and FluxMicroMenuConfig.IsMinimapRowId and FluxMicroMenuConfig:IsMinimapRowId(rowId) then
        return true
    end
    if FluxMicroMenuConfig and FluxMicroMenuConfig.IsTradeSkillRowId and FluxMicroMenuConfig:IsTradeSkillRowId(rowId) then
        if FluxTradeSkillMicro and FluxTradeSkillMicro.IsRowActiveOnBar then
            return FluxTradeSkillMicro:IsRowActiveOnBar(rowId)
        end
        return false
    end
    if FluxMicroMenuConfig and FluxMicroMenuConfig.IsTradeSkillFlyoutRowId
        and FluxMicroMenuConfig:IsTradeSkillFlyoutRowId(rowId) then
        if FluxTradeSkillMicro and FluxTradeSkillMicro.IsRowActiveOnBar then
            return FluxTradeSkillMicro:IsRowActiveOnBar(rowId)
        end
        return false
    end
    if rowId == "FluxLFGMicroButton" then
        if self:HasBlizzardGroupFinderMicroButton() then
            return false
        end
        return ClientHasMinimapGroupFinder()
    end
    if IsFluxCustomMicroButtonName(rowId) then
        return true
    end
    local f = _G[rowId]
    if f and f.IsObjectType and f:IsObjectType("Frame") then
        return ClientHasMicroMenuFeature(rowId)
    end
    return false
end

--- Default unified row order: canonical native list first, then any extra discovered natives / M2M proxies.
--- Minimap-derived frames become M2M:sourceName; raw FluxMinimap2Micro_* global names are never used as rowIds.
--- Trade-skill rows (TSK:* / flyout) are injected immediately before FluxAddonMicroButton.
function FluxMicroMenu:GetDefaultUnifiedRowIds()
    local cfg = FluxMicroMenuConfig
    local out = {}
    local seen = {}

    local function appendTradeSkillRows()
        if not FluxTradeSkillMicro or not FluxTradeSkillMicro.GetActiveBarRowIds then
            return
        end
        for _, rowId in ipairs(FluxTradeSkillMicro:GetActiveBarRowIds()) do
            if self:IsNativeRowAvailableOnClient(rowId) and not seen[rowId] then
                seen[rowId] = true
                table.insert(out, rowId)
            end
        end
    end

    for _, rowId in ipairs(DEFAULT_UNIFIED_NATIVE_ROW_ORDER) do
        if rowId == "FluxAddonMicroButton" then
            appendTradeSkillRows()
        end
        if self:IsNativeRowAvailableOnClient(rowId) and not seen[rowId] then
            seen[rowId] = true
            table.insert(out, rowId)
        end
    end

    -- If Addon button was unavailable on this client, still append trade skills before M2M extras
    -- (no-op when Addon already triggered appendTradeSkillRows via seen[]).
    if not seen["FluxAddonMicroButton"] then
        appendTradeSkillRows()
    end

    for _, info in ipairs(DiscoverButtonInfos()) do
        local rowId
        local btn = info.btn
        if btn and btn.minimapButtonName and cfg then
            rowId = cfg:MakeMinimapRowId(btn.minimapButtonName)
        elseif btn and btn.tradeSkillKey and cfg and cfg.MakeTradeSkillRowId then
            rowId = cfg:MakeTradeSkillRowId(btn.tradeSkillKey)
        elseif info.name and string.match(info.name, "^FluxMinimap2Micro_") then
            rowId = nil
        elseif info.name and string.match(info.name, "^FluxTradeSkill_") then
            -- Prefer TSK: row ids; skip raw global names when tradeSkillKey missing
            rowId = (btn and btn.tradeSkillKey and cfg and cfg.MakeTradeSkillRowId)
                and cfg:MakeTradeSkillRowId(btn.tradeSkillKey) or nil
        else
            rowId = info.name
        end
        if rowId and not seen[rowId] and self:IsNativeRowAvailableOnClient(rowId) then
            seen[rowId] = true
            table.insert(out, rowId)
        end
    end
    return out
end

---------------------------------------------------------------------
-- 4. Layout Logic
-- ---------------------------------------------------------------------------

FluxMicroMenu.buttons = {}

--- Horizontal gap between buttons: Blizzard default (API) plus optional offset from FluxOptions → MicroMenu.
function FluxMicroMenu:GetLayoutSpacing()
    local base = -3
    if FluxGetMicroButtonSpacing then
        local ok, s = pcall(FluxGetMicroButtonSpacing)
        if ok and type(s) == "number" then
            base = s
        end
    end
    local off = 0
    if FluxOptions and FluxOptions.GetMicroMenuDB then
        local m = FluxOptions:GetMicroMenuDB()
        if m and type(m.buttonSpacingOffset) == "number" then
            off = m.buttonSpacingOffset
        end
    end
    return base + off
end

--- Uniform scale for micro button hit boxes (1 = native size). Clamped for sanity.
function FluxMicroMenu:GetButtonSizeScale()
    local s = 0.9
    if FluxOptions and FluxOptions.GetMicroMenuDB then
        local m = FluxOptions:GetMicroMenuDB()
        if m and type(m.buttonSizeScale) == "number" and m.buttonSizeScale > 0 then
            s = m.buttonSizeScale
        end
    end
    if s < 0.5 then
        s = 0.5
    elseif s > 1.5 then
        s = 1.5
    end
    return s
end

--- Retail DF HUD: MainMenuBarMicroButtonMixin sets GetNormalTexture():SetAlpha(0) on OnEnter (highlight uses
--- separate art). Reparenting micro buttons onto FluxMicroMenu can skip OnLeave, leaving the icon alpha at 0
--- so talents/spec (and other HUD) icons look missing or "transparent" until the next hover cycle.
local function FluxFixRetailHudMicroButtonPaint(btn, useDfHudLayout)
    if not useDfHudLayout or not btn or not btn.GetNormalTexture or not btn.IsMouseOver then
        return
    end
    if btn:IsMouseOver() then
        return
    end
    local nt = btn:GetNormalTexture()
    if nt and nt.SetAlpha then
        nt:SetAlpha(1)
    end
    -- OnDisable sets frame alpha 0.5; if enabled state returns without OnEnable, resync.
    if btn.IsEnabled and btn:IsEnabled() and btn.SetAlpha then
        btn:SetAlpha(1)
    end
end

--- Match FluxChatFrame GetChatHeight when chat module has not loaded yet.
local function GetPrimaryChatHeightFallback()
    local base = 200 * 1.35
    if FluxWindowFrame and FluxWindowFrame.WINDOW_HEIGHT then
        base = FluxWindowFrame.WINDOW_HEIGHT
    end
    return math.max(120, base - 100)
end

local function GetPrimaryChatHeightForMicroMenu()
    if _G.FluxChatFrame_GetPrimaryChatHeight then
        local ok, h = pcall(_G.FluxChatFrame_GetPrimaryChatHeight)
        if ok and type(h) == "number" and h > 0 then
            return h
        end
    end
    return GetPrimaryChatHeightFallback()
end

local function GetPrimaryBottomInsetYForMicroMenu()
    if _G.FluxChatFrame_GetPrimaryBottomInsetY then
        local ok, y = pcall(_G.FluxChatFrame_GetPrimaryBottomInsetY)
        if ok and type(y) == "number" then
            return y
        end
    end
    return 0
end

--- Tighter atlas padding for vertical column; restore default for horizontal bar.
local function SyncFluxMicroMenuBorderPadding(isBesideChat)
    if not FluxBorder or not FluxMicroMenu then
        return
    end
    local want = isBesideChat and "compact_v2" or "default"
    if FluxMicroMenu._fluxBorderMode == want then
        return
    end
    FluxBorder:RemoveFrom(FluxMicroMenu)
    if isBesideChat then
        -- Minimal inset: border close to buttons (position 2 inner padding is near zero).
        FluxBorder:ApplyTo(FluxMicroMenu, -2, -2, 0, 0)
    else
        FluxBorder:ApplyTo(FluxMicroMenu)
    end
    FluxBorder:SetClassColor(FluxMicroMenu)
    if FluxMicroMenu.FluxBorderFrame then
        FluxMicroMenu.FluxBorderFrame:SetFrameStrata("MEDIUM")
        FluxMicroMenu.FluxBorderFrame:SetFrameLevel(6)
    end
    FluxMicroMenu._fluxBorderMode = want
end

local BESIDE_CHAT_ABOVE_GRID_GAP = 3 -- vertical gap: micromenu bottom sits above FluxUnifiedBorderFrame top
local BESIDE_CHAT_LEFT_INSET = 2
local BESIDE_CHAT_MIN_COLUMN_H = 48

--- Frame edge in UIParent units. GetLeft/GetTop are screen-px / frame effective scale.
local function FrameEdgeInUIParent(frame, getter)
    if not frame or type(getter) ~= "function" then
        return nil
    end
    local ok, v = pcall(getter, frame)
    if not ok or type(v) ~= "number" or v ~= v then
        return nil
    end
    local fes = (frame.GetEffectiveScale and frame:GetEffectiveScale()) or 1
    local ues = (UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()) or 1
    if type(fes) == "number" and fes > 0 and type(ues) == "number" and ues > 0 then
        return v * fes / ues
    end
    return v
end

local function GetUIParentSize()
    local w = (UIParent and UIParent.GetWidth and UIParent:GetWidth()) or 1024
    local h = (UIParent and UIParent.GetHeight and UIParent:GetHeight()) or 768
    if type(w) ~= "number" or w ~= w or w < 1 then
        w = 1024
    end
    if type(h) ~= "number" or h ~= h or h < 1 then
        h = 768
    end
    return w, h
end

--- Keep pos2 on-screen. Live ChatFrame1 anchors follow per-character FCF/Edit Mode restores off the display.
local function ClampBesideChatColumn(x, yBot, w, h, uiW, uiH)
    if type(uiW) ~= "number" or uiW ~= uiW or uiW < 1 then
        uiW = 1024
    end
    if type(uiH) ~= "number" or uiH ~= uiH or uiH < 1 then
        uiH = 768
    end
    if type(w) ~= "number" or w ~= w or w < 1 then
        w = 1
    end
    if type(h) ~= "number" or h ~= h then
        h = BESIDE_CHAT_MIN_COLUMN_H
    end
    if h < BESIDE_CHAT_MIN_COLUMN_H then
        h = BESIDE_CHAT_MIN_COLUMN_H
    end
    local maxH = math.max(BESIDE_CHAT_MIN_COLUMN_H, uiH - 4)
    if h > maxH then
        h = maxH
    end
    if type(x) ~= "number" or x ~= x then
        x = BESIDE_CHAT_LEFT_INSET
    end
    if type(yBot) ~= "number" or yBot ~= yBot then
        yBot = 0
    end
    x = math.max(0, math.min(x, math.max(0, uiW - w)))
    yBot = math.max(0, yBot)
    if yBot + h > uiH then
        yBot = math.max(0, uiH - h)
    end
    return x, yBot, w, h
end

local function EnsureMicroMenuScrollParts()
    if FluxMicroMenu._scrollFrame then
        return FluxMicroMenu._scrollFrame, FluxMicroMenu._scrollChild
    end
    local sf = CreateFrame("ScrollFrame", "FluxMicroMenuScrollFrame", FluxMicroMenu)
    local child = CreateFrame("Frame", "FluxMicroMenuScrollChild", sf)
    sf:SetScrollChild(child)
    sf:EnableMouse(true)
    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(self, delta)
        local sc = self:GetScrollChild()
        if not sc or not self.GetHeight or not sc.GetHeight then
            return
        end
        local sh = self:GetHeight()
        local ch = sc:GetHeight()
        local maxOffset = math.max(0, ch - sh)
        local step = 32
        local v = self:GetVerticalScroll() - delta * step
        if v < 0 then
            v = 0
        elseif v > maxOffset then
            v = maxOffset
        end
        self:SetVerticalScroll(v)
    end)
    FluxMicroMenu._scrollFrame = sf
    FluxMicroMenu._scrollChild = child
    return sf, child
end

--- Horizontal strip (layout position 1 only): viewport narrower than full row; wheel pans along the row.
local function EnsureMicroMenuHorizontalScrollParts()
    if FluxMicroMenu._hScrollFrame then
        return FluxMicroMenu._hScrollFrame, FluxMicroMenu._hScrollChild
    end
    local sf = CreateFrame("ScrollFrame", "FluxMicroMenuHScrollFrame", FluxMicroMenu)
    local child = CreateFrame("Frame", "FluxMicroMenuHScrollChild", sf)
    sf:SetScrollChild(child)
    sf:EnableMouse(true)
    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(self, delta)
        local sc = self:GetScrollChild()
        if not sc or not self.GetWidth or not sc.GetWidth then
            return
        end
        local sw = self:GetWidth()
        local cw = sc:GetWidth()
        local maxOffset = math.max(0, cw - sw)
        local step = 32
        -- Wheel down (delta negative) → scroll right; wheel up → scroll left.
        local h = self:GetHorizontalScroll() - delta * step
        if h < 0 then
            h = 0
        elseif h > maxOffset then
            h = maxOffset
        end
        self:SetHorizontalScroll(h)
    end)
    FluxMicroMenu._hScrollFrame = sf
    FluxMicroMenu._hScrollChild = child
    return sf, child
end

--- Dragonflight+ HUD micro path (32x40 atlas); false on Classic / pre-DF where native shells vary.
--- Must be defined before UpdateLayoutHorizontal (Lua local functions are not hoisted).
local function ShouldUseDfHudMicroLayout()
    if not FluxShouldApplyMicroButtonTopGapLayout then
        return false
    end
    local ok, v = pcall(FluxShouldApplyMicroButtonTopGapLayout)
    return ok and v == true
end

--- Beside-chat / minimap vertical strip only: DF-style row gaps and grid (includes pre-DF + Edit Mode parity).
local function ShouldUseDfVerticalMicroMenuGrid()
    if not FluxShouldUseDfStyleVerticalMicroMenuGrid then
        return false
    end
    local ok, v = pcall(FluxShouldUseDfStyleVerticalMicroMenuGrid)
    return ok and v == true
end

local function ClearBesideChatColumnReservation()
    FluxMicroMenu._besideChatReserveWidth = nil
    FluxMicroMenu._besideChatColumnRightX = nil
end

--- Right edge of the pos2 micromenu column in UIParent units (not width). Chat and status loc2 add their gaps to this.
function _G.FluxMicroMenu_GetBesideChatColumnRightX()
    if FluxOptions and FluxOptions.GetMicroMenuLayoutPosition and FluxOptions:GetMicroMenuLayoutPosition() ~= 2 then
        return nil
    end
    local mm = FluxMicroMenu
    if not mm then
        return nil
    end
    local r = mm._besideChatColumnRightX
    if type(r) == "number" and r == r and r > 0 then
        return r
    end
    local reserve = mm._besideChatReserveWidth
    if type(reserve) == "number" and reserve > 8 then
        return BESIDE_CHAT_LEFT_INSET + reserve
    end
    if mm.GetWidth then
        local width = mm:GetWidth()
        if type(width) == "number" and width > 8 then
            return BESIDE_CHAT_LEFT_INSET + width
        end
    end
    return nil
end

local function UpdateLayoutHorizontal(rowInfo, padding, spacing, btnSizeScale, layoutTopGap, legacyHeightPad, scaledStdHeight)
    ClearBesideChatColumnReservation()
    local totalWidth = padding
    local maxHeight = 0
    for _, r in ipairs(rowInfo) do
        totalWidth = totalWidth + r.w + spacing
        if r.h > maxHeight then
            maxHeight = r.h
        end
    end
    if #rowInfo > 0 then
        totalWidth = totalWidth - spacing
    end
    totalWidth = totalWidth + padding

    local minBarW = tonumber(FluxMicroMenu.MIN_BAR_WIDTH) or 250
    if minBarW < 0 then
        minBarW = 0
    end
    local contentW = math.max(minBarW, totalWidth)
    local leftInset = padding + math.max(0, (contentW - totalWidth) / 2)

    local menuLeft = 2
    local microTargetGap = 3
    local upw = (UIParent and UIParent.GetWidth and UIParent:GetWidth()) or 800
    local maxRight
    if _G.FluxUnitFrames_GetPlacement1TargetLeftForMicroMenuCap then
        local ok, tl = pcall(_G.FluxUnitFrames_GetPlacement1TargetLeftForMicroMenuCap)
        if ok and type(tl) == "number" and tl == tl then
            maxRight = tl - microTargetGap
        else
            maxRight = upw - 8
        end
    else
        maxRight = upw - 8
    end
    local maxViewport = math.max(0, maxRight - menuLeft)
    local viewportW = math.max(minBarW, math.min(contentW, maxViewport))
    local useHScroll = contentW > maxViewport + 0.5

    local useDfHudLayout = ShouldUseDfHudMicroLayout()

    local adjustedHeight
    if useDfHudLayout then
        adjustedHeight = maxHeight + (padding * 2) + legacyHeightPad
        if layoutTopGap > 0 then
            adjustedHeight = adjustedHeight - layoutTopGap
        end
        local minBarHeight = scaledStdHeight + (padding * 2) + legacyHeightPad
        if layoutTopGap > 0 then
            minBarHeight = minBarHeight - layoutTopGap
        end
        if adjustedHeight < minBarHeight then
            adjustedHeight = minBarHeight
        end
    else
        adjustedHeight = maxHeight + (padding * 2)
        local rawTopGap = 0
        if FluxGetMicroButtonTopGap then
            local ok, tg = pcall(FluxGetMicroButtonTopGap)
            rawTopGap = (ok and tg) or 0
        end
        if rawTopGap > 0 then
            adjustedHeight = math.max(1, adjustedHeight - rawTopGap)
        end
    end

    if FluxMicroMenu._scrollFrame then
        FluxMicroMenu._scrollFrame:Hide()
    end

    local anchorParent = FluxMicroMenu
    if useHScroll then
        local sf, child = EnsureMicroMenuHorizontalScrollParts()
        anchorParent = child
        child:SetSize(math.max(1, contentW), math.max(1, adjustedHeight))
        sf:ClearAllPoints()
        sf:SetPoint("TOPLEFT", FluxMicroMenu, "TOPLEFT", 0, 0)
        sf:SetPoint("BOTTOMRIGHT", FluxMicroMenu, "BOTTOMRIGHT", 0, 0)
        sf:Show()
        sf:SetHorizontalScroll(0)
    elseif FluxMicroMenu._hScrollFrame then
        FluxMicroMenu._hScrollFrame:Hide()
    end

    local previousBtn = nil
    local bottomOffset = padding + layoutTopGap
    local legacyBottomOffset = padding
    for _, r in ipairs(rowInfo) do
        local btn = r.btn
        if useHScroll then
            btn:SetParent(anchorParent)
        end
        if previousBtn then
            btn:SetPoint("BOTTOMLEFT", previousBtn, "BOTTOMRIGHT", spacing, 0)
        else
            local yOff = useDfHudLayout and bottomOffset or legacyBottomOffset
            btn:SetPoint("BOTTOMLEFT", anchorParent, "BOTTOMLEFT", leftInset, yOff)
        end
        FluxFixRetailHudMicroButtonPaint(btn, useDfHudLayout)
        previousBtn = btn
    end

    FluxMicroMenu:ClearAllPoints()
    FluxMicroMenu:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 2, 0)

    FluxMicroMenu:SetAlpha(1)
    FluxMicroMenu:SetWidth(viewportW)
    FluxMicroMenu:SetHeight(adjustedHeight)

    if FluxUpdateTalentMicroButtonPreDF then
        FluxUpdateTalentMicroButtonPreDF()
    end

    if _G.FluxStatusBarUpdateLayout then
        _G.FluxStatusBarUpdateLayout()
    end
    SyncFluxMicroMenuBorderPadding(false)
end

--- Buttons that are not the classic micro shell; use measured size for stride/width (rare).
local BESIDE_CHAT_SIZE_EXCEPTION_NAMES = {
    StoreMicroButton = true,
    ShopMicroButton = true,
}

--- Beside-chat vertical strip: native Blizzard *MicroButton (excludes Flux custom *MicroButton).
local function IsBesideChatNativeBlizzardMicro(btn)
    if not btn or not btn.GetName then
        return false
    end
    if IsFluxUserScalableMicroButton(btn) then
        return false
    end
    local nm = btn:GetName() or ""
    return nm:match("MicroButton$") ~= nil
end

--- Pre-DF: unscaled half nominal shell height; added to SetPoint Y so natives sit slightly higher (tighter gaps).
local function GetBesideChatPreDfHalfMicroLiftY()
    local _, sh = 29, 37
    if FluxGetStandardMicroButtonSize then
        _, sh = FluxGetStandardMicroButtonSize()
    end
    return (sh or 37) * 0.5
end

--- Scroll child height from laid-out buttons (parent = scroll child). GetBottom() can be wrong/stale until
--- after a layout pass — use as a supplement only, not the sole source, or scrolling breaks (ch ≈ sh).
local function GetBesideChatScrollContentHeightFromButtons(gridEntries, padding)
    local minBottom = -padding
    for _, entry in ipairs(gridEntries) do
        local btn = entry and entry.btn
        if btn and btn.GetBottom then
            local ok, b = pcall(btn.GetBottom, btn)
            if ok and type(b) == "number" and b < minBottom then
                minBottom = b
            end
        end
    end
    return padding - minBottom
end

--- Row-major: each row height = max(r.h) in that row; gaps between rows match anchor spacing (vertLinkGap / rowSpacing).
local function GetBesideChatScrollContentHeightComputed(gridEntries, padding, gapBetweenRows, colCount, n)
    if n < 1 then
        return math.max(1, padding * 2)
    end
    colCount = math.max(1, math.floor(colCount + 0.5))
    local numRows = math.ceil(n / colCount)
    local contentH = padding
    for row = 1, numRows do
        local rh = 0
        for c = 1, colCount do
            local idx = (row - 1) * colCount + c
            local e = gridEntries[idx]
            if e and type(e.h) == "number" and e.h > 0 then
                rh = math.max(rh, e.h)
            end
        end
        contentH = contentH + rh
        if row < numRows then
            contentH = contentH + (gapBetweenRows or 0)
        end
    end
    return contentH + padding
end

--- Shared vertical grid (beside chat and minimap popup): returns gridW, contentH; nil if empty.
local function RunVerticalMicroMenuGridLayout(rowInfo, padding, spacing, btnSizeScale, colsPerRow)
    SyncFluxMicroMenuBorderPadding(true)

    -- (spacing + 3) tracks the Micro Menu tab offset when API base is ~-3. Do not clamp at 0: negative offset
    -- must tighten the grid (negative gaps / overlap), same idea as the horizontal bar.
    local cellGap = spacing + 3
    if cellGap < -12 then
        cellGap = -12
    elseif cellGap > 16 then
        cellGap = 16
    end
    local colSpacing = cellGap
    local rowSpacing
    if ShouldUseDfVerticalMicroMenuGrid() then
        -- DF-style beside-chat / row-major: conservative vertical step vs cellGap. Pre-DF + Edit Mode keeps 0.55
        -- (parity with retail DF strip); post-DF without top-gap layout falls back to 0.28.
        local rowGapMult = 0.55
        if FluxShouldApplyMicroButtonTopGapLayout then
            local ok, dfHud = pcall(FluxShouldApplyMicroButtonTopGapLayout)
            if not ok or not dfHud then
                if FLUX_API and FLUX_API.isPostDF then
                    rowGapMult = 0.28
                end
            end
        elseif FLUX_API and FLUX_API.isPostDF then
            rowGapMult = 0.28
        end
        rowSpacing = math.floor(cellGap * rowGapMult + 0.5)
    else
        --- Pre-DF: horizontal column gap uses full `cellGap` (spacing slider + API). Old 0.28× here made
        --- vertical row spacing almost ignore the same slider; use a larger share so rows track the config.
        local preDfBesideRowGapMult = 0.78
        rowSpacing = math.floor(cellGap * preDfBesideRowGapMult + 0.5)
    end
    local pos2FrameInset = 0
    local sf, child = EnsureMicroMenuScrollParts()
    sf:Show()
    sf:SetParent(FluxMicroMenu)
    sf:ClearAllPoints()
    sf:SetPoint("TOPLEFT", FluxMicroMenu, "TOPLEFT", pos2FrameInset, -pos2FrameInset)
    sf:SetPoint("BOTTOMRIGHT", FluxMicroMenu, "BOTTOMRIGHT", -pos2FrameInset, pos2FrameInset)

    local gridEntries = {}
    for _, r in ipairs(rowInfo) do
        r.btn:Show()
        r.btn:ClearAllPoints()
        r.btn:SetParent(child)
        table.insert(gridEntries, r)
    end

    local useDfHudLayout = ShouldUseDfHudMicroLayout()
    local useDfVerticalGrid = ShouldUseDfVerticalMicroMenuGrid()

    local n = #gridEntries
    if n == 0 then
        ClearBesideChatColumnReservation()
        FluxMicroMenu:SetSize(1, 1)
        FluxMicroMenu:SetAlpha(0)
        if _G.FluxStatusBarUpdateLayout then
            _G.FluxStatusBarUpdateLayout()
        end
        return nil, nil
    end

    local colCount = colsPerRow
    if type(colCount) == "string" then
        colCount = tonumber(colCount)
    end
    if type(colCount) ~= "number" or colCount < 1 then
        colCount = 2
    end
    colCount = math.floor(colCount + 0.5)
    if colCount < 1 then
        colCount = 1
    elseif colCount > 8 then
        colCount = 8
    end

    for _, r in ipairs(gridEntries) do
        --- DF-style vertical grid uses per-cell height; legacy pre-DF uses anchor chains (no manual stride).
        if useDfVerticalGrid then
            r.layoutStride = r.h
        end
    end

    local stdW0 = 29
    if FluxGetStandardMicroButtonSize then
        stdW0 = select(1, FluxGetStandardMicroButtonSize()) or 29
    end
    local preDfCellW = stdW0 * (btnSizeScale or 1)

    local colWidths = {}
    for c = 1, colCount do
        colWidths[c] = 0
    end
    for i, r in ipairs(gridEntries) do
        local c = ((i - 1) % colCount) + 1
        local cellW = r.w
        if not useDfVerticalGrid then
            local nm = r.btn and r.btn.GetName and (r.btn:GetName() or "") or ""
            if BESIDE_CHAT_SIZE_EXCEPTION_NAMES[nm] then
                cellW = math.max(preDfCellW, r.w)
            end
        end
        colWidths[c] = math.max(colWidths[c], cellW)
    end

    local gridW = padding * 2
    for c = 1, colCount do
        gridW = gridW + colWidths[c]
        if c < colCount then
            gridW = gridW + colSpacing
        end
    end

    local vGap = rowSpacing
    local vertLinkGap = vGap
    --- Native Blizzard rows: nudge TOP up by half nominal shell (layout units) to shorten gaps vs custom/chain.
    local preDfHalfLiftY = 0
    if not useDfVerticalGrid then
        preDfHalfLiftY = GetBesideChatPreDfHalfMicroLiftY()
    end
    local contentH
    local useLegacyColumnStacks = (not useDfVerticalGrid) and colCount > 1

    if useLegacyColumnStacks then
        --- Pre-DF: row-major placement. Column 1 stacks vertically (TOP/BOTTOM chain). Cells 2..k in the same row
        --- use BOTTOMLEFT→BOTTOMRIGHT like the horizontal micromenu so Flux custom and Blizzard share one bottom Y.
        local rowStart = 1
        while rowStart <= n do
            local rowEnd = math.min(rowStart + colCount - 1, n)
            local first = gridEntries[rowStart]
            if first and first.btn then
                local lift = (preDfHalfLiftY > 0 and IsBesideChatNativeBlizzardMicro(first.btn)) and preDfHalfLiftY or 0
                local x = padding
                if rowStart == 1 then
                    first.btn:SetPoint("TOPLEFT", child, "TOPLEFT", x, -padding + lift)
                else
                    local above = gridEntries[rowStart - colCount] and gridEntries[rowStart - colCount].btn
                    if above then
                        first.btn:SetPoint("TOPLEFT", above, "BOTTOMLEFT", 0, -vertLinkGap + lift)
                    else
                        first.btn:SetPoint("TOPLEFT", child, "TOPLEFT", x, -padding + lift)
                    end
                end
                FluxFixRetailHudMicroButtonPaint(first.btn, useDfHudLayout)
                for i = rowStart + 1, rowEnd do
                    local entry = gridEntries[i]
                    local prev = gridEntries[i - 1] and gridEntries[i - 1].btn
                    if entry and entry.btn and prev then
                        entry.btn:SetPoint("BOTTOMLEFT", prev, "BOTTOMRIGHT", colSpacing, 0)
                        FluxFixRetailHudMicroButtonPaint(entry.btn, useDfHudLayout)
                    end
                end
            end
            rowStart = rowEnd + 1
        end
        local gapBetweenRows = useDfVerticalGrid and rowSpacing or vertLinkGap
        contentH = math.max(
            GetBesideChatScrollContentHeightComputed(gridEntries, padding, gapBetweenRows, colCount, n),
            GetBesideChatScrollContentHeightFromButtons(gridEntries, padding)
        )
    elseif colCount == 1 then
        for i = 1, n do
            local entry = gridEntries[i]
            if entry then
                local lift = (preDfHalfLiftY > 0 and IsBesideChatNativeBlizzardMicro(entry.btn)) and preDfHalfLiftY or 0
                if i == 1 then
                    entry.btn:SetPoint("TOPLEFT", child, "TOPLEFT", padding, -padding + lift)
                else
                    local prev = gridEntries[i - 1].btn
                    if prev then
                        local g = useDfVerticalGrid and rowSpacing or vertLinkGap
                        entry.btn:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -g + lift)
                    else
                        entry.btn:SetPoint("TOPLEFT", child, "TOPLEFT", padding, -padding + lift)
                    end
                end
                FluxFixRetailHudMicroButtonPaint(entry.btn, useDfHudLayout)
            end
        end
        local gapBetweenRows = useDfVerticalGrid and rowSpacing or vertLinkGap
        contentH = math.max(
            GetBesideChatScrollContentHeightComputed(gridEntries, padding, gapBetweenRows, colCount, n),
            GetBesideChatScrollContentHeightFromButtons(gridEntries, padding)
        )
    else
        --- DF HUD multi-column: row-major grid (pre-DF multi-col uses column stacks above).
        local numRows = math.ceil(n / colCount)
        local rowHeights = {}
        for row = 1, numRows do
            local rh = 0
            for c = 1, colCount do
                local idx = (row - 1) * colCount + c
                local cell = gridEntries[idx]
                if cell then
                    rh = math.max(rh, cell.layoutStride or cell.h)
                end
            end
            rowHeights[row] = rh
        end

        contentH = padding
        for row = 1, numRows do
            contentH = contentH + rowHeights[row]
            if row < numRows then
                contentH = contentH + rowSpacing
            end
        end
        contentH = contentH + padding

        local yTop = -padding
        for row = 1, numRows do
            for c = 1, colCount do
                local idx = (row - 1) * colCount + c
                local entry = gridEntries[idx]
                if entry then
                    local x = padding
                    for cc = 1, c - 1 do
                        x = x + colWidths[cc] + colSpacing
                    end
                    entry.btn:SetPoint("TOPLEFT", child, "TOPLEFT", x, yTop)
                    FluxFixRetailHudMicroButtonPaint(entry.btn, useDfHudLayout)
                end
            end
            yTop = yTop - rowHeights[row] - rowSpacing
        end
    end

    return gridW, contentH
end

--- Multi-column grid beside chat: top aligns with intended chat tab row; bottom above action/grid UnifiedBorder.
--- Anchored to UIParent only. Never parent/point to ChatFrame1 — per-character FCF scale, Edit Mode, and
--- RestorePosition drag the chat frame off-screen and used to take the micromenu with it.
local function UpdateLayoutBesideChat(rowInfo, padding, spacing, btnSizeScale, colsPerRow)
    local gridW, contentH = RunVerticalMicroMenuGridLayout(rowInfo, padding, spacing, btnSizeScale, colsPerRow)
    if not gridW or not contentH then
        return
    end
    local pos2FrameInset = 0
    local sf, child = EnsureMicroMenuScrollParts()

    local chatCap = GetPrimaryChatHeightForMicroMenu()
    local yChatBottom = GetPrimaryBottomInsetYForMicroMenu()
    local yIntendedTop = yChatBottom + chatCap
    if _G.FluxChatFrame_GetPrimaryColumnTopY then
        local ok, t = pcall(_G.FluxChatFrame_GetPrimaryColumnTopY)
        if ok and type(t) == "number" and t == t and t > yChatBottom then
            yIntendedTop = t
        end
    end

    local ubTop = nil
    if _G.FluxUnifiedBorder and _G.FluxUnifiedBorder.GetActionGridBorderTop then
        ubTop = _G.FluxUnifiedBorder.GetActionGridBorderTop()
    end

    local yBot
    if type(ubTop) == "number" and ubTop == ubTop then
        yBot = ubTop + BESIDE_CHAT_ABOVE_GRID_GAP
    else
        yBot = yChatBottom
    end

    local columnOuterH
    if yIntendedTop > yBot + 16 then
        columnOuterH = yIntendedTop - yBot
    else
        columnOuterH = math.min(contentH, chatCap)
    end
    columnOuterH = math.max(BESIDE_CHAT_MIN_COLUMN_H, columnOuterH)

    child:SetSize(math.max(1, gridW), math.max(1, contentH))
    sf:SetVerticalScroll(0)

    local totalW = gridW + pos2FrameInset * 2
    local uiW, uiH = GetUIParentSize()
    local x, yClamped, w, h = ClampBesideChatColumn(BESIDE_CHAT_LEFT_INSET, yBot, totalW, columnOuterH, uiW, uiH)

    FluxMicroMenu:SetParent(UIParent)
    if FluxMicroMenu.SetScale then
        FluxMicroMenu:SetScale(1)
    end
    FluxMicroMenu:ClearAllPoints()
    FluxMicroMenu:SetAlpha(1)
    FluxMicroMenu:SetSize(w, h)
    FluxMicroMenu:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, yClamped)

    sf:ClearAllPoints()
    sf:SetPoint("TOPLEFT", FluxMicroMenu, "TOPLEFT", pos2FrameInset, -pos2FrameInset)
    sf:SetPoint("BOTTOMRIGHT", FluxMicroMenu, "BOTTOMRIGHT", -pos2FrameInset, pos2FrameInset)

    -- Same-pass guard: if something else already offset the frame, pin it back to the clamped UIParent point.
    local leftNow = FrameEdgeInUIParent(FluxMicroMenu, FluxMicroMenu.GetLeft)
    if type(leftNow) == "number" and leftNow < -4 then
        FluxMicroMenu:ClearAllPoints()
        FluxMicroMenu:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, yClamped)
    end

    --- Column width plus the actual right edge after clamp. Chat/status add their gaps to the right edge
    --- (not width-as-if-x-were-0). Safe to use GetRight here: this column is pinned to UIParent, not ChatFrame1.
    FluxMicroMenu._besideChatReserveWidth = w
    local rightNow = FrameEdgeInUIParent(FluxMicroMenu, FluxMicroMenu.GetRight)
    if type(rightNow) == "number" and rightNow > 0 then
        FluxMicroMenu._besideChatColumnRightX = rightNow
    else
        FluxMicroMenu._besideChatColumnRightX = x + w
    end
    if _G.FluxChatFrame_ApplyPrimaryPosition then
        _G.FluxChatFrame_ApplyPrimaryPosition()
    end

    if FluxUpdateTalentMicroButtonPreDF then
        FluxUpdateTalentMicroButtonPreDF()
    end

    if _G.FluxStatusBarUpdateLayout then
        _G.FluxStatusBarUpdateLayout()
    end
end

-- Minimap vertical strip (position 3): dock at Minimap right edge; optional expand/collapse via chevron.
local MINIMAP_STRIP_TOGGLE_W = 22
--- Above Minimap (usually MEDIUM) so strip + border paint over map chrome.
local MINIMAP_STRIP_STRATA = "HIGH"
local FluxMicroMenuMinimapDock
local FluxMicroMenuMinimapToggle
local minimapSizeHookRegistered

local function HideFluxMicroMenuMinimapDock()
    if FluxMicroMenuMinimapDock then
        FluxMicroMenuMinimapDock:Hide()
    end
end

local function FluxMicroMenuMinimapStrip_OnToggleClick()
    if InCombatLockdown() then
        if FluxMicroMenu then
            FluxMicroMenu.needsUpdate = true
        end
        return
    end
    if FluxOptions and FluxOptions.GetMicroMenuLayoutPosition and FluxOptions:GetMicroMenuLayoutPosition() ~= 3 then
        return
    end
    if FluxOptions and FluxOptions.SetMicroMenuMinimapStripExpanded and FluxOptions.GetMicroMenuMinimapStripExpanded then
        FluxOptions:SetMicroMenuMinimapStripExpanded(not FluxOptions:GetMicroMenuMinimapStripExpanded())
    end
    if FluxMicroMenu and FluxMicroMenu.Rebuild then
        FluxMicroMenu:Rebuild()
    end
end

local function FluxMicroMenuMinimapStrip_OnToggleEnter(self)
    if not GameTooltip then
        return
    end
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    local expanded = FluxOptions and FluxOptions.GetMicroMenuMinimapStripExpanded
        and FluxOptions:GetMicroMenuMinimapStripExpanded()
    if expanded then
        GameTooltip:SetText("Hide micro menu", 1, 1, 1)
        GameTooltip:AddLine("Collapse the micro button strip. You can open it again from this arrow.", 0.85, 0.85, 0.85, true)
    else
        GameTooltip:SetText("Micro menu", 1, 1, 1)
        GameTooltip:AddLine("Show micro buttons in a strip to the left of the minimap.", 0.85, 0.85, 0.85, true)
    end
    if InCombatLockdown() then
        GameTooltip:AddLine("Cannot change layout in combat.", 0.75, 0.25, 0.25, true)
    end
    GameTooltip:Show()
end

local function FluxMicroMenuMinimapStrip_OnToggleLeave()
    if GameTooltip then
        GameTooltip:Hide()
    end
end

local function EnsureFluxMicroMenuMinimapDock()
    if FluxMicroMenuMinimapDock then
        return FluxMicroMenuMinimapDock, FluxMicroMenuMinimapToggle
    end
    local dock = CreateFrame("Frame", "FluxMicroMenuMinimapDock", UIParent)
    dock:SetFrameStrata(MINIMAP_STRIP_STRATA)
    dock:SetFrameLevel(500)
    dock:Hide()
    local toggle = CreateFrame("Button", "FluxMicroMenuMinimapToggle", dock)
    toggle:SetSize(MINIMAP_STRIP_TOGGLE_W, MINIMAP_STRIP_TOGGLE_W)
    toggle:SetPoint("TOPRIGHT", dock, "TOPRIGHT", 0, 0)
    toggle:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    toggle:SetScript("OnClick", FluxMicroMenuMinimapStrip_OnToggleClick)
    toggle:SetScript("OnEnter", FluxMicroMenuMinimapStrip_OnToggleEnter)
    toggle:SetScript("OnLeave", FluxMicroMenuMinimapStrip_OnToggleLeave)
    local arrow = toggle:CreateTexture(nil, "ARTWORK")
    arrow:SetSize(16, 16)
    arrow:SetPoint("CENTER", toggle, "CENTER", 0, 0)
    toggle._fluxArrow = arrow
    local hl = toggle:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.22)
    toggle:SetHighlightTexture(hl)
    FluxMicroMenuMinimapDock = dock
    FluxMicroMenuMinimapToggle = toggle
    return dock, toggle
end

local function UpdateFluxMicroMenuMinimapToggleVisual(expanded)
    local toggle = FluxMicroMenuMinimapToggle
    if not toggle or not toggle._fluxArrow then
        return
    end
    local arrow = toggle._fluxArrow
    if expanded then
        if arrow.SetAtlas then
            local ok = pcall(arrow.SetAtlas, arrow, "common-icon-rotateright", true)
            if not ok then
                arrow:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
            end
        else
            arrow:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
        end
    else
        if arrow.SetAtlas then
            local ok = pcall(arrow.SetAtlas, arrow, "common-icon-rotateleft", true)
            if not ok then
                arrow:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
            end
        else
            arrow:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
        end
    end
end

local function RegisterMinimapStripSizeHook()
    if not Minimap or minimapSizeHookRegistered then
        return
    end
    Minimap:HookScript("OnSizeChanged", function()
        if not FluxOptions or not FluxOptions.GetMicroMenuLayoutPosition or FluxOptions:GetMicroMenuLayoutPosition() ~= 3 then
            return
        end
        if FluxMicroMenu and FluxMicroMenu.Rebuild and not InCombatLockdown() then
            FluxMicroMenu:Rebuild()
        end
    end)
    minimapSizeHookRegistered = true
end

--- Position 3: draw entire micromenu strip above Minimap and its children (border uses MEDIUM from Sync; re-layer here).
local function ApplyMicroMenuMinimapPos3Layering(dock, toggle)
    if not dock then
        return
    end
    local base = 500
    dock:SetFrameStrata(MINIMAP_STRIP_STRATA)
    dock:SetFrameLevel(base)
    if FluxMicroMenu then
        FluxMicroMenu:SetFrameStrata(MINIMAP_STRIP_STRATA)
        FluxMicroMenu:SetFrameLevel(base + 10)
    end
    local sf = FluxMicroMenu and FluxMicroMenu._scrollFrame
    if sf then
        sf:SetFrameStrata(MINIMAP_STRIP_STRATA)
        sf:SetFrameLevel(base + 12)
    end
    if FluxMicroMenu and FluxMicroMenu.FluxBorderFrame then
        local bf = FluxMicroMenu.FluxBorderFrame
        bf:SetFrameStrata(MINIMAP_STRIP_STRATA)
        bf:SetFrameLevel(base + 14)
    end
    if toggle then
        toggle:SetFrameStrata(MINIMAP_STRIP_STRATA)
        toggle:SetFrameLevel(base + 20)
    end
    if dock.Raise then
        pcall(dock.Raise, dock)
    end
    if FluxMicroMenu and FluxMicroMenu.Raise then
        pcall(FluxMicroMenu.Raise, FluxMicroMenu)
    end
end

local function UpdateLayoutMinimapStrip(rowInfo, padding, spacing, btnSizeScale, colsPerRow)
    ClearBesideChatColumnReservation()

    if not Minimap or not Minimap.GetHeight then
        HideFluxMicroMenuMinimapDock()
        FluxMicroMenu:SetSize(1, 1)
        FluxMicroMenu:SetAlpha(0)
        if _G.FluxStatusBarUpdateLayout then
            _G.FluxStatusBarUpdateLayout()
        end
        return
    end

    if Minimap.IsShown and not Minimap:IsShown() then
        HideFluxMicroMenuMinimapDock()
        if FluxMicroMenu:GetParent() ~= UIParent then
            FluxMicroMenu:SetParent(UIParent)
        end
        FluxMicroMenu:SetSize(1, 1)
        FluxMicroMenu:SetAlpha(0)
        if _G.FluxStatusBarUpdateLayout then
            _G.FluxStatusBarUpdateLayout()
        end
        return
    end

    local expanded = FluxOptions and FluxOptions.GetMicroMenuMinimapStripExpanded and FluxOptions:GetMicroMenuMinimapStripExpanded()
    local gridW, contentH = RunVerticalMicroMenuGridLayout(rowInfo, padding, spacing, btnSizeScale, colsPerRow)
    if not gridW or not contentH then
        return
    end

    local columnOuterH = Minimap:GetHeight()
    if not columnOuterH or columnOuterH < 1 then
        columnOuterH = 140
    end
    columnOuterH = math.max(48, columnOuterH)

    local dock, toggle = EnsureFluxMicroMenuMinimapDock()
    RegisterMinimapStripSizeHook()

    local sf, child = EnsureMicroMenuScrollParts()
    child:SetSize(math.max(1, gridW), math.max(1, contentH))
    sf:SetVerticalScroll(0)

    local pos2FrameInset = 0
    local totalW = gridW + pos2FrameInset * 2
    local toggleW = MINIMAP_STRIP_TOGGLE_W

    FluxMicroMenu:SetParent(dock)
    FluxMicroMenu:ClearAllPoints()
    FluxMicroMenu:SetAlpha(1)

    toggle:ClearAllPoints()
    toggle:SetPoint("TOPRIGHT", dock, "TOPRIGHT", 0, 0)
    toggle:SetSize(toggleW, toggleW)
    UpdateFluxMicroMenuMinimapToggleVisual(expanded)

    if expanded then
        FluxMicroMenu:Show()
        FluxMicroMenu:SetAlpha(1)
        sf:Show()
        FluxMicroMenu:SetSize(totalW, columnOuterH)
        --- Strip fills dock to the left of the reserved toggle column; arrow stays a small hitbox top-right.
        FluxMicroMenu:SetPoint("TOPRIGHT", dock, "TOPRIGHT", -toggleW, 0)
        dock:SetSize(toggleW + totalW, columnOuterH)
        sf:ClearAllPoints()
        sf:SetPoint("TOPLEFT", FluxMicroMenu, "TOPLEFT", pos2FrameInset, -pos2FrameInset)
        sf:SetPoint("BOTTOMRIGHT", FluxMicroMenu, "BOTTOMRIGHT", -pos2FrameInset, pos2FrameInset)
    else
        FluxMicroMenu:SetSize(1, columnOuterH)
        FluxMicroMenu:SetPoint("TOPRIGHT", dock, "TOPRIGHT", -toggleW, 0)
        FluxMicroMenu:SetAlpha(0)
        if sf then
            sf:Hide()
        end
        for _, r in ipairs(rowInfo) do
            if r and r.btn and r.btn.Hide then
                r.btn:Hide()
            end
        end
        dock:SetSize(toggleW, columnOuterH)
    end

    dock:ClearAllPoints()
    dock:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", 0, 0)
    dock:Show()
    ApplyMicroMenuMinimapPos3Layering(dock, toggle)

    if FluxUpdateTalentMicroButtonPreDF then
        FluxUpdateTalentMicroButtonPreDF()
    end

    if _G.FluxStatusBarUpdateLayout then
        _G.FluxStatusBarUpdateLayout()
    end
end

--- Retail DF+ QueueStatusButton lives on the minimap; pre-DF keeps it beside the micro row.
local function PositionFluxQueueStatusBesideMicroMenu()
    local q = _G.QueueStatusButton
    if not q or not q.ClearAllPoints or not q.SetPoint then
        return
    end
    if q.IsForbidden and q:IsForbidden() then
        return
    end
    q:SetParent(UIParent)
    q:ClearAllPoints()
    if q.SetScale then
        q:SetScale(1)
    end
    local layoutPos = 1
    if FluxOptions and FluxOptions.GetMicroMenuLayoutPosition then
        layoutPos = FluxOptions:GetMicroMenuLayoutPosition()
    end
    local gap = 6
    if layoutPos == 2 or layoutPos == 3 then
        q:SetPoint("BOTTOM", FluxMicroMenu, "TOP", 0, gap)
    else
        q:SetPoint("BOTTOMLEFT", FluxMicroMenu, "BOTTOMRIGHT", gap, 0)
    end
end

_G.FluxMicroMenu_PositionQueueStatusFallback = PositionFluxQueueStatusBesideMicroMenu

local function PositionFluxQueueStatusButton()
    -- Dragonflight+ retail: dungeon/queue eye on minimap corners.
    if FluxMinimap and FluxMinimap.PositionQueueStatusEye then
        if FluxMinimap:PositionQueueStatusEye() then
            return
        end
    end
    -- Pre-DF / no QueueStatusButton path: beside micromenu.
    PositionFluxQueueStatusBesideMicroMenu()
end

local function EnsureFluxQueueStatusUpdateHook()
    if FluxMicroMenu._fluxQueueStatusHooked then
        return
    end
    FluxMicroMenu._fluxQueueStatusHooked = true

    -- Retail DF+: FluxMinimap owns QueueStatusButton placement on the minimap.
    if FluxMinimap and FluxMinimap.EnsureQueueStatusEyeHooks then
        FluxMinimap:EnsureQueueStatusEyeHooks()
    end

    -- Pre-DF / non-managed path: keep eye beside the micro row when Blizzard repositions it.
    local q = _G.QueueStatusButton
    if q and type(q.UpdatePosition) == "function" then
        hooksecurefunc(q, "UpdatePosition", function()
            -- Micro menu Edit Mode enter / exit move the eye inside its pass.
            if FluxEditModeBusy and FluxEditModeBusy() then
                FluxAfterEditMode(PositionFluxQueueStatusButton)
                return
            end
            PositionFluxQueueStatusButton()
        end)
    end
end

--- Pre-DF Flux custom: 18×25 icon on 29×37 shell; icon scales with bar size slider.
local NOM_PRE_DF_W, NOM_PRE_DF_H = 29, 37
local NOM_PRE_DF_ICON_W, NOM_PRE_DF_ICON_H = 18, 25
FluxApplyPreDfCustomMicroButtonIconLayout = function(btn, pushed)
    if not btn or not btn.icon then
        return
    end
    if ShouldUseDfHudMicroLayout() then
        return
    end
    if not IsFluxUserScalableMicroButton(btn) then
        return
    end
    local w = btn:GetWidth()
    local h = btn:GetHeight()
    if not w or not h or w <= 0 or h <= 0 then
        return
    end
    local sx = w / NOM_PRE_DF_W
    local sy = h / NOM_PRE_DF_H
    local icon = btn.icon
    icon:SetSize(NOM_PRE_DF_ICON_W * sx, NOM_PRE_DF_ICON_H * sy)
    local offY = pushed and -2 or -1
    icon:SetPoint("CENTER", btn, "CENTER", 0, offY * sy)
end

--- Pre-DF Character micro: global portrait stays at local scale 1 and inherits CharacterMicroButton :SetScale
--- (uniform zoom). Do not ClearAllPoints/SetSize on the legacy SetScale path — Blizzard placement drifts if reset
--- every layout. Pre-DF + Edit Mode uses SetSize×slider on the button — portrait must scale explicitly.
-- Ref: MainMenuBarMicroButtons.xml MicroButtonPortrait 18×25, CENTER 0,-1
local NOM_CHAR_MICRO_PORTRAIT_W, NOM_CHAR_MICRO_PORTRAIT_H = 18, 25
local NOM_CHAR_MICRO_PORTRAIT_OFF_Y = -1

local function FluxSyncMicroButtonPortraitWithCharacterButton(btn, btnSizeScale, usePreDfEditSetSizeLayout)
    if ShouldUseDfHudMicroLayout() then
        return
    end
    if not btn or btn:GetName() ~= "CharacterMicroButton" then
        return
    end
    local por = _G.MicroButtonPortrait
    if not por or not por.SetScale or not por.GetParent then
        return
    end
    if por:GetParent() ~= btn then
        return
    end
    if usePreDfEditSetSizeLayout and btnSizeScale and btnSizeScale > 0 then
        por:SetScale(1)
        if por.SetSize then
            por:SetSize(
                NOM_CHAR_MICRO_PORTRAIT_W * btnSizeScale,
                NOM_CHAR_MICRO_PORTRAIT_H * btnSizeScale
            )
        end
        if por.ClearAllPoints and por.SetPoint then
            por:ClearAllPoints()
            por:SetPoint("CENTER", btn, "CENTER", 0, NOM_CHAR_MICRO_PORTRAIT_OFF_Y * btnSizeScale)
        end
    else
        --- Native pre-DF + SetScale(slider): only ensure portrait local scale 1; inherits button scale uniformly.
        por:SetScale(1)
    end
end

--- MainMenuMicroButton: OVERLAY PerformanceIndicator (latency-colored bar; XML fixed 14×9 + offsets) does not
--- inherit SetSize-based scaling — only uniform SetScale scales it. Re-apply when using SetSize×slider (pre-DF+Edit Mode).
-- Ref: Blizzard_MicroMenu/.../MainMenuBarMicroButtons.xml MainMenuMicroButton Layers PerformanceIndicator
local MAINMENU_PERF_NOM_W, MAINMENU_PERF_NOM_H = 14, 9
local MAINMENU_PERF_OFF_X, MAINMENU_PERF_OFF_Y = 10, -13

local function FluxSyncMainMenuMicroPerformanceIndicator(btn, scale)
    if not btn or not scale or scale <= 0 then
        return
    end
    if btn:GetName() ~= "MainMenuMicroButton" then
        return
    end
    local perf = btn.PerformanceIndicator
    if not perf or not perf.SetSize or not perf.ClearAllPoints or not perf.SetPoint then
        return
    end
    perf:SetSize(MAINMENU_PERF_NOM_W * scale, MAINMENU_PERF_NOM_H * scale)
    perf:ClearAllPoints()
    perf:SetPoint("TOPLEFT", btn, "TOPLEFT", MAINMENU_PERF_OFF_X * scale, MAINMENU_PERF_OFF_Y * scale)
end

--- DF HUD Flux custom micro: icon insets scale with frame so icons stay centered when bar size slider changes.
local NOM_DF_MICRO_W, NOM_DF_MICRO_H = 32, 40
FluxApplyDfHudCustomMicroButtonIconLayout = function(btn, pushed)
    if not btn or not btn.icon then
        return
    end
    if not ShouldUseDfHudMicroLayout() then
        return
    end
    if not IsFluxUserScalableMicroButton(btn) then
        return
    end
    local w = btn:GetWidth()
    local h = btn:GetHeight()
    if not w or not h or w <= 0 or h <= 0 then
        return
    end
    local sx = w / NOM_DF_MICRO_W
    local sy = h / NOM_DF_MICRO_H
    local icon = btn.icon
    if pushed then
        icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -6 * sx, 6 * sy)
        icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 8 * sx, -8 * sy)
    else
        icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 7 * sx, -7 * sy)
        icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -7 * sx, 7 * sy)
    end
    local hl = btn._fluxMicroHighlight
    if hl and hl.ClearAllPoints and hl.SetAllPoints then
        hl:ClearAllPoints()
        hl:SetAllPoints(icon)
    end
end

--- True while ESC game menu, Edit Mode, or logout confirmation is active.
--- Addon layout during GameMenuFrame:InitButtons() taints Log Out / Exit / Edit Mode.
local function FluxGameMenuBlocksMicroTaintWork()
    if FLUX_API and FLUX_API.SecureUIPanelsBlockInsecureWork then
        return FLUX_API.SecureUIPanelsBlockInsecureWork()
    end
    local gm = _G.GameMenuFrame
    if not gm then
        return false
    end
    if gm.IsShown and gm:IsShown() then
        return true
    end
    if gm.IsVisible and gm:IsVisible() then
        return true
    end
    return false
end

local function UpdateLayout()
    if InCombatLockdown() then return end
    if FluxGameMenuBlocksMicroTaintWork() then return end
    local padding = 4
    local spacing = FluxMicroMenu:GetLayoutSpacing()
    local btnSizeScale = FluxMicroMenu:GetButtonSizeScale()
    local besideChatCols = 2
    local layoutTopGap = 0
    if FluxGetMicroMenuLayoutTopGap then
        local ok, g = pcall(FluxGetMicroMenuLayoutTopGap)
        layoutTopGap = (ok and g) or 0
    end
    local legacyHeightPad = 0
    if FluxGetMicroMenuLegacyBarHeightExtra then
        local ok, extra = pcall(FluxGetMicroMenuLegacyBarHeightExtra)
        legacyHeightPad = (ok and extra) or 0
    end

    local _, stdHeight = FluxGetStandardMicroButtonSize()
    local scaledStdHeight = stdHeight * btnSizeScale

    local layoutPos = 1
    if FluxOptions and FluxOptions.GetMicroMenuLayoutPosition then
        layoutPos = FluxOptions:GetMicroMenuLayoutPosition()
    end

    if layoutPos ~= 1 and FluxMicroMenu._hScrollFrame then
        FluxMicroMenu._hScrollFrame:Hide()
    end

    if layoutPos ~= 3 then
        HideFluxMicroMenuMinimapDock()
        if FluxMicroMenu:GetParent() ~= UIParent then
            FluxMicroMenu:SetParent(UIParent)
        end
    end

    local layoutButtons = {}
    local seenLayout = {}
    for _, b in ipairs(FluxMicroMenu.buttons) do
        if b and not seenLayout[b] then
            seenLayout[b] = true
            table.insert(layoutButtons, b)
        end
    end

    local rowInfo = {}
    local useDfHudLayout = ShouldUseDfHudMicroLayout()
    --- Pre-DF + Edit Mode: vertical grid matches DF strip; use one SetSize×slider (canonical shell) for natives so
    --- SetScale does not stack with Edit Mode, and use sw/sh like Flux custom buttons (GetSize can be smaller).
    local useDfVerticalGrid = ShouldUseDfVerticalMicroMenuGrid()
    local usePreDfEditNativeBlizzardSetSizeOnly = (not useDfHudLayout) and useDfVerticalGrid
    for _, btn in ipairs(layoutButtons) do
        if btn then
            btn:Show()
            btn:ClearAllPoints()
            btn:SetParent(FluxMicroMenu)
            btn:SetScale(1)
            local btnWidth, btnHeight = FluxStandardizeMicroButton(btn)
            local isFluxScalable = IsFluxUserScalableMicroButton(btn)
            if useDfHudLayout then
                btnWidth = btnWidth * btnSizeScale
                btnHeight = btnHeight * btnSizeScale
                btn:SetSize(btnWidth, btnHeight)
                if isFluxScalable and FluxApplyDfHudCustomMicroButtonIconLayout then
                    FluxApplyDfHudCustomMicroButtonIconLayout(btn, false)
                end
            else
                local sw, sh = 29, 37
                if FluxGetStandardMicroButtonSize then
                    sw, sh = FluxGetStandardMicroButtonSize()
                end
                if isFluxScalable then
                    --- Flux custom: SetSize-based scaling from canonical shell.
                    btnWidth = sw * btnSizeScale
                    btnHeight = sh * btnSizeScale
                    btn:SetSize(btnWidth, btnHeight)
                    if FluxApplyPreDfCustomMicroButtonIconLayout then
                        FluxApplyPreDfCustomMicroButtonIconLayout(btn, false)
                    end
                else
                    --- Blizzard pre-DF: normally native size + slider via SetScale (uniform zoom for portrait).
                    --- Pre-DF + Edit Mode: avoid SetScale stacking; size from canonical sw/sh like custom buttons.
                    local bw, bh = btnWidth, btnHeight
                    if not bw or bw <= 0 then
                        bw = sw
                    end
                    if not bh or bh <= 0 then
                        bh = sh
                    end
                    if usePreDfEditNativeBlizzardSetSizeOnly then
                        btn:SetScale(1)
                        btnWidth = sw * btnSizeScale
                        btnHeight = sh * btnSizeScale
                        btn:SetSize(btnWidth, btnHeight)
                    else
                        btn:SetSize(bw, bh)
                        btn:SetScale(btnSizeScale)
                        btnWidth = bw * btnSizeScale
                        btnHeight = bh * btnSizeScale
                    end
                    FluxSyncMicroButtonPortraitWithCharacterButton(btn, btnSizeScale, usePreDfEditNativeBlizzardSetSizeOnly)
                    if usePreDfEditNativeBlizzardSetSizeOnly then
                        FluxSyncMainMenuMicroPerformanceIndicator(btn, btnSizeScale)
                    end
                end
            end
            table.insert(rowInfo, { btn = btn, w = btnWidth, h = btnHeight })
        end
    end

    if #rowInfo == 0 then
        ClearBesideChatColumnReservation()
        if FluxMicroMenu._hScrollFrame then
            FluxMicroMenu._hScrollFrame:Hide()
        end
        FluxMicroMenu:SetSize(1, 1)
        FluxMicroMenu:SetAlpha(0)
        if _G.FluxStatusBarUpdateLayout then
            _G.FluxStatusBarUpdateLayout()
        end
        if _G.FluxChatFrame_ApplyPrimaryPosition then
            _G.FluxChatFrame_ApplyPrimaryPosition()
        end
        return
    end

    if layoutPos == 2 then
        padding = 0
        if FluxOptions and FluxOptions.GetMicroMenuBesideChatColumns then
            besideChatCols = FluxOptions:GetMicroMenuBesideChatColumns()
        end
        UpdateLayoutBesideChat(rowInfo, padding, spacing, btnSizeScale, besideChatCols)
    elseif layoutPos == 3 then
        padding = 0
        if FluxOptions and FluxOptions.GetMicroMenuBesideChatColumns then
            besideChatCols = FluxOptions:GetMicroMenuBesideChatColumns()
        end
        UpdateLayoutMinimapStrip(rowInfo, padding, spacing, btnSizeScale, besideChatCols)
    else
        UpdateLayoutHorizontal(rowInfo, padding, spacing, btnSizeScale, layoutTopGap, legacyHeightPad, scaledStdHeight)
    end

    if _G.FluxChatFrame_ApplyPrimaryPosition then
        _G.FluxChatFrame_ApplyPrimaryPosition()
    end

    EnsureFluxQueueStatusUpdateHook()
    PositionFluxQueueStatusButton()
    EnsureCharacterOutfitRightClick()
end

--- Re-run layout without rediscovering buttons (e.g. after unit frame size / placement refresh).
function FluxMicroMenu:RefreshLayout()
    if InCombatLockdown() then
        self.needsUpdate = true
        return
    end
    UpdateLayout()
end

-- ---------------------------------------------------------------------------
-- 6. Protection
-- ---------------------------------------------------------------------------



-- ---------------------------------------------------------------------------
-- 7. Hijack Implementation
-- ---------------------------------------------------------------------------

local OPTIONAL_MICRO_MENU_STUB_NAMES = {
    "AchievementMicroButton",
    "PlayerSpellsMicroButton",
    "HousingMicroButton",
    "CollectionsMicroButton",
    "PVPMicroButton",
    "EJMicroButton",
    "LFDMicroButton",
    "LFGMicroButton",
    "SearchLFGButton",
}

local function ParkUnavailableOptionalMicroButtons(hiddenParent)
    if InCombatLockdown() or not hiddenParent then
        return
    end
    for _, name in ipairs(OPTIONAL_MICRO_MENU_STUB_NAMES) do
        if not ClientHasMicroMenuFeature(name) then
            local btn = _G[name]
            if btn and btn.IsObjectType and btn:IsObjectType("Frame") then
                btn:SetParent(hiddenParent)
                btn:Hide()
                btn:EnableMouse(false)
                if not btn.FluxStubMicroHideHooked then
                    btn.FluxStubMicroHideHooked = true
                    local btnName = name
                    local parkParent = hiddenParent
                    btn:HookScript("OnShow", function(self)
                        if not InCombatLockdown() and not ClientHasMicroMenuFeature(btnName) then
                            self:SetParent(parkParent)
                            self:Hide()
                            self:EnableMouse(false)
                        end
                    end)
                end
            end
        end
    end
end

-- MicroMenu GetEdgeButton compares GetCenter() of every layoutIndex child,
-- including hidden ones. Grid layout only positions shown children, so leftover
-- hidden Socials/Help/Store after hijack yields compare-two-nils inside Edit Mode
-- UpdateSystems. Do not replace GetEdgeButton or Layout (taint). Do not Hide or
-- SetParent MicroMenuContainer (InitSystemAnchors SetPointBase taint).
local function GetParkParentForLeftoverMicroMenuChild()
    local hiddenParent = _G.FluxHiddenParent or FluxHiddenParent
    if isRetail then
        return hiddenParent
    end
    return FluxMicroMenu or hiddenParent
end

local function ParkFrameOffMicroMenu(frame, parkParent)
    if not frame or not parkParent then
        return
    end
    if frame.SetParent then
        frame:SetParent(parkParent)
    end
    if frame.Hide then
        frame:Hide()
    end
    if frame.EnableMouse then
        frame:EnableMouse(false)
    end
end

local function ParkLeftoverMicroMenuLayoutChildren()
    if InCombatLockdown() then
        return
    end
    local menu = _G.MicroMenu
    if not menu or not menu.GetChildren then
        return
    end
    local parkParent = GetParkParentForLeftoverMicroMenuChild()
    if not parkParent then
        return
    end
    local keep = {}
    local buttons = FluxMicroMenu.buttons
    if buttons then
        for i = 1, #buttons do
            local btn = buttons[i]
            if btn then
                keep[btn] = true
            end
        end
    end
    local children = { menu:GetChildren() }
    for i = 1, #children do
        local child = children[i]
        if child and child.layoutIndex and not keep[child] then
            local childName = child.GetName and child:GetName()
            if not FluxMicroMenu:ShouldLeaveBlizzardButtonShown(childName) then
                ParkFrameOffMicroMenu(child, parkParent)
            end
        end
    end
    local ticket = _G.HelpOpenWebTicketButton
    if ticket then
        ParkFrameOffMicroMenu(ticket, parkParent)
    end
end

-- Edit Mode re-lays out MicroMenu while it closes. Park leftovers after that
-- pass, never from a hook inside it: RevertAllChanges → InitSystemAnchors runs
-- before ResetTargetAndFocus, and reparenting Blizzard buttons there taints it.
local editModeMicroParkRegistered = false

local function WatchEditModeMicroMenuSanitize()
    if editModeMicroParkRegistered or not (EventRegistry and EventRegistry.RegisterCallback) then
        return
    end
    editModeMicroParkRegistered = true
    EventRegistry:RegisterCallback("EditMode.Exit", function()
        if FluxAfterEditMode then
            FluxAfterEditMode(function()
                ParkLeftoverMicroMenuLayoutChildren()
                if ScheduleBesideChatStayOnScreen then ScheduleBesideChatStayOnScreen() end
            end, "MicroMenu.EditExit")
        end
    end)
end

local function HijackButtons()
    if InCombatLockdown() or FluxGameMenuBlocksMicroTaintWork() then
        FluxMicroMenu.needsUpdate = true
        return false
    end
    if FluxEditModeBusy and FluxEditModeBusy() then
        FluxAfterEditMode(HijackButtons)
        return false
    end

    local discovered = DiscoverButtons()
    local newButtons = discovered
    local hiddenParent = _G.FluxHiddenParent
    if FluxMicroMenuConfig and FluxMicroMenuConfig.BuildOrderedMicroButtons then
        newButtons, _ = FluxMicroMenuConfig:BuildOrderedMicroButtons(discovered)
        if hiddenParent and FluxMicroMenuConfig.ParkHiddenButtons then
            FluxMicroMenuConfig:ParkHiddenButtons(discovered, newButtons, hiddenParent)
        end
        ParkUnavailableOptionalMicroButtons(hiddenParent)
    end
    FluxMicroMenu.buttons = newButtons
    
    -- Special handling for MainMenuMicroButton to fix tooltip fighting logic

    
    -- Force Tooltip Anchoring for buttons (Custom & Native). Skip MainMenuMicroButton — it opens GameMenuFrame;
    -- HookScript from addon code on that control contributes to secure-action taint on Log Out / Exit Game.
    for _, btn in ipairs(newButtons) do
        if btn and btn ~= _G.MainMenuMicroButton and btn.HookScript and not btn._FluxTooltipAnchorHooked then
           btn._FluxTooltipAnchorHooked = true
           btn:HookScript("OnEnter", function(self)
               if GameTooltip and GameTooltip:IsOwned(self) then
                   -- Re-anchor WITHOUT resetting text (SetOwner clears text)
                   GameTooltip:ClearAllPoints()
                   GameTooltip:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", 0, 0) 
                   -- ANCHOR_RIGHT behaves roughly like BOTTOMLEFT of tooltip to BOTTOMRIGHT of owner
               end
           end)
        end
    end
    
    -- Handle Hide List
    for name, shouldHide in pairs(BUTTONS_TO_HIDE) do
        if shouldHide then
            -- Safely check if this is MainMenuBarDownload which might be needed on some clients?
            -- Actually user said "Game Menu" missing. MainMenuMicroButton is 1.
            -- But "MainMenuBarDownload" is hidden. Let's unhide it just in case it's related on their client
            -- or serves as a placeholder.
            if name ~= "MainMenuBarDownload" and not FluxMicroMenu:ShouldLeaveBlizzardButtonShown(name) then
                local btn = _G[name]
                if btn then
                    btn:SetParent(FluxHiddenParent)
                    btn:Hide()
                end
            end
        end
    end

    if not FluxGameMenuBlocksMicroTaintWork() and FluxUpdateTalentMicroButtonPreDF then
        FluxUpdateTalentMicroButtonPreDF()
    end

    FluxRefreshCharacterMicroMouseover()
    UpdateLayout()
    ParkLeftoverMicroMenuLayoutChildren()
    WatchEditModeMicroMenuSanitize()
    -- Native controls stay usable until their moved replacements have a layout.
    DisableBlizzardLayout()
    FluxMicroMenu.needsUpdate = false
    return true
end

-- Use a flag-based approach to avoid taint issues with game menu
local pendingLayoutUpdate = false
local pendingDiscoveryUpdate = false
local layoutUpdateFrame = CreateFrame("Frame")
layoutUpdateFrame:Hide()
layoutUpdateFrame:SetScript("OnUpdate", function(self)
    self:Hide()
    pendingLayoutUpdate = false
    local discover = pendingDiscoveryUpdate
    pendingDiscoveryUpdate = false
    if InCombatLockdown() or FluxGameMenuBlocksMicroTaintWork() then
        FluxMicroMenu.needsUpdate = true
    elseif discover then
        InvalidateDiscoverCacheInternal()
        HijackButtons()
    else
        UpdateLayout()
    end
end)

RequestDiscoveryRefresh = function()
    if managedStartup and not Flux.loggedIn then return end
    if InCombatLockdown() then
        FluxMicroMenu.needsUpdate = true
        return
    end
    pendingDiscoveryUpdate = true
    if not pendingLayoutUpdate then
        pendingLayoutUpdate = true
        layoutUpdateFrame:Show()
    end
end

-- Classic/Anniversary: refresh bar after Blizzard's UpdateMicroButtons SetPoint chain.
-- Do NOT replace the global UpdateMicroButtons with addon code — that taints the function and breaks
-- secure callers (GameMenuFrame, Edit Mode, etc.) with ADDON_ACTION_FORBIDDEN on menu actions.
local isMainlineProject = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
local classicMicroRebuildThisFrame = false
local function ArmClassicMicroRebuildCoalesce()
    if classicMicroRebuildThisFrame then return end
    classicMicroRebuildThisFrame = true
    C_Timer.After(0, function()
        classicMicroRebuildThisFrame = false
    end)
end

-- Flux perf T2.10: Blizzard's UpdateMicroButtons fires for many reasons that do
-- not actually change the discovered-button set on Classic (e.g., keybinding
-- rebinds, tooltip refreshes, cooldown tick-throughs, vehicle state changes).
-- We compute a cheap identity hash of the discovered button names + visibility
-- and skip the full Rebuild when unchanged. The hash path reuses the cached
-- DiscoverButtonInfos table so it does no scan of its own.
local _classicLastRebuildHash
local function _ComputeClassicMicroHash()
    local infos = DiscoverButtonInfos()
    if not infos or #infos == 0 then return "empty" end
    local parts = {}
    for i = 1, #infos do
        local info = infos[i]
        local btn = info and info.btn
        local shown = (btn and btn.IsShown and btn:IsShown()) and "1" or "0"
        parts[#parts + 1] = (info and info.name or "?") .. shown
    end
    return table.concat(parts, "|")
end

-- Coalesce the UpdateMicroButtons hook body to one pass per frame. Blizzard
-- can re-fire UpdateMicroButtons several times back-to-back (e.g., during
-- character-select/login or an Edit Mode flush); the expensive bits inside
-- (Rebuild, FluxUpdateTalentMicroButtonPreDF, layout schedule) only need to
-- run once per frame.
local microHookPending = false
local function _FluxRunMicroHookBody()
    microHookPending = false
    if FluxGameMenuBlocksMicroTaintWork() then
        return
    end
    local skipMicroLayout = false
    if not isMainlineProject and not InCombatLockdown() and FluxMicroMenu and FluxMicroMenu.Rebuild then
        local hash = _ComputeClassicMicroHash()
        if hash == _classicLastRebuildHash then
            skipMicroLayout = true
        elseif not classicMicroRebuildThisFrame then
            _classicLastRebuildHash = hash
            FluxMicroMenu:Rebuild()
            ArmClassicMicroRebuildCoalesce()
        end
    end
    if FluxUpdateTalentMicroButtonPreDF then
        FluxUpdateTalentMicroButtonPreDF()
    end
    if skipMicroLayout then
        return
    end
    if not pendingLayoutUpdate then
        pendingLayoutUpdate = true
        layoutUpdateFrame:Show()
    end
end

-- Forever GameMenuFrame:OnShow calls UpdateMicroButtons() and then the gamepad footer,
-- which calls protected SetPreferredGamepadInteractTarget(). A hooksecurefunc here
-- taints that caller (same failure mode as ActionBarController_UpdateAll). Login,
-- regen, and talent events already rebuild the bar.
local fluxSkipUpdateMicroButtonsHook = (Flux and Flux.Client and (Flux.Client.isCamelot or Flux.Client.isForever))
    or (FLUX_API and (FLUX_API.isCamelot or FLUX_API.isForever))
if UpdateMicroButtons and not fluxSkipUpdateMicroButtonsHook then
    hooksecurefunc("UpdateMicroButtons", function()
        if FluxGameMenuBlocksMicroTaintWork() then
            return
        end
        if microHookPending then return end
        microHookPending = true
        if C_Timer and C_Timer.After then
            C_Timer.After(0, _FluxRunMicroHookBody)
        else
            _FluxRunMicroHookBody()
        end
    end)
end

-- Public API to force a full rebuild (discovery + layout)
function FluxMicroMenu:Rebuild()
    HijackButtons()
end

-- ---------------------------------------------------------------------------
-- 8. HelpTip Notification Fix
-- ---------------------------------------------------------------------------

-- Shared anchor frame for microbutton notifications to prevent memory leaks
local notificationAnchorFrame = nil

local function FluxMicroMenuLogoutStaticPopupVisible()
    local vis = _G.StaticPopup_Visible
    if type(vis) ~= "function" then
        return false
    end
    return vis("CAMP") or vis("QUIT") or vis("PLUNDERSTORM_LEAVE")
end

-- Post-hook HelpTip:Show to fix microbutton notification positioning without replacing HelpTip.Show (assignment
-- taints the global entry point and can break secure callers). After Blizzard's Show runs, re-anchor via Hide+Show.
local function FixMicroButtonNotifications()
    if FluxMicroMenu._notificationHooked then return end
    if not (FLUX_API and FLUX_API.hasHelpTip_Show) then return end
    if not HelpTip or type(HelpTip.Show) ~= "function" or not hooksecurefunc then return end

    -- Create shared anchor frame if it doesn't exist
    if not notificationAnchorFrame then
        notificationAnchorFrame = CreateFrame("Frame", "FluxMicroMenuNotificationAnchor", UIParent)
        notificationAnchorFrame:SetSize(1, 1)
        notificationAnchorFrame:Hide()  -- Hidden by default, positioned when needed
    end

    local skipFluxHelpTipPostHook = false
    hooksecurefunc(HelpTip, "Show", function(self, parent, info, relativeRegion)
        if skipFluxHelpTipPostHook then
            return
        end
        if not self or not relativeRegion or not info or not FluxMicroMenu.buttons then
            return
        end
        for _, btn in ipairs(FluxMicroMenu.buttons) do
            if btn == relativeRegion then
                if FluxMicroMenuLogoutStaticPopupVisible() then
                    break
                end
                local menuTop = FluxMicroMenu:GetTop()
                local menuLeft = FluxMicroMenu:GetLeft()
                local menuRight = FluxMicroMenu:GetRight()
                if menuTop and menuLeft and menuRight then
                    local menuCenterX = (menuLeft + menuRight) / 2
                    notificationAnchorFrame:ClearAllPoints()
                    notificationAnchorFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", menuCenterX, menuTop + 5)
                    notificationAnchorFrame:Show()

                    local modifiedInfo = CopyTable(info)
                    modifiedInfo.targetPoint = HelpTip.Point.TopEdgeCenter
                    modifiedInfo.alignment = HelpTip.Alignment.Center
                    modifiedInfo.offsetX = 0
                    modifiedInfo.offsetY = 0

                    skipFluxHelpTipPostHook = true
                    pcall(function()
                        if self.Hide then
                            self:Hide(parent, info.text)
                        end
                        self:Show(parent, modifiedInfo, notificationAnchorFrame)
                    end)
                    skipFluxHelpTipPostHook = false
                end
                break
            end
        end
    end)
    FluxMicroMenu._notificationHooked = true
end

-- ---------------------------------------------------------------------------
-- 9. Initialization
-- ---------------------------------------------------------------------------

WatchEditModeMicroMenuSanitize()

FluxMicroMenu:RegisterEvent("PLAYER_LOGIN")
FluxMicroMenu:RegisterEvent("ADDON_LOADED")
FluxMicroMenu:RegisterEvent("PLAYER_REGEN_ENABLED")
FluxMicroMenu:RegisterEvent("PLAYER_LEVEL_UP")
FluxMicroMenu:RegisterEvent("PLAYER_ENTERING_WORLD")
FluxMicroMenu:RegisterEvent("PLAYER_TALENT_UPDATE")
FluxMicroMenu:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
ScheduleBesideChatStayOnScreen = function()
    if InCombatLockdown() then
        FluxMicroMenu.needsUpdate = true
        return
    end
    if FluxGameMenuBlocksMicroTaintWork() then
        return
    end
    if not FluxOptions or not FluxOptions.GetMicroMenuLayoutPosition then
        return
    end
    if FluxOptions:GetMicroMenuLayoutPosition() ~= 2 then
        return
    end
    if not pendingLayoutUpdate then
        pendingLayoutUpdate = true
        layoutUpdateFrame:Show()
    end
end

-- Chat restores may occur long after login. Follow actual restore/size events
-- rather than assuming three fixed startup delays cover every client.
local chatSettleHooks = {}
local function EnsureChatSettleHooks()
    local chat = _G.ChatFrame1
    if chat and chat.HookScript and not chat.FluxMicroMenuSettleHooked then
        chat:HookScript("OnSizeChanged", ScheduleBesideChatStayOnScreen)
        chat:HookScript("OnShow", ScheduleBesideChatStayOnScreen)
        chat.FluxMicroMenuSettleHooked = true
    end
    if not hooksecurefunc then return end
    for _, name in ipairs({ "FCF_RestorePositionAndDimensions", "FCF_DockUpdate" }) do
        if not chatSettleHooks[name] and type(_G[name]) == "function" then
            hooksecurefunc(name, function() ScheduleBesideChatStayOnScreen() end)
            chatSettleHooks[name] = true
        end
    end
end

local function InitializeMicroMenu()
    if managedStartup and not Flux.loggedIn then return false end
    if FluxMicroMenu._startupReady then return true end
    if HijackButtons() == false then return false end
    FixMicroButtonNotifications()
    EnsureChatSettleHooks()
    FluxMicroMenu._startupReady = true
    if Flux and Flux.Startup then Flux.Startup.Mark("micromenu_ready") end
    return true
end

if managedStartup then
    Flux.Module.Register("MicroMenu", {
        phase = "hud", priority = 40, protected = true, OnEnable = InitializeMicroMenu,
    })
end

if UIParent and UIParent.HookScript and not UIParent.FluxMicroMenuPos2SizeHooked then
    UIParent.FluxMicroMenuPos2SizeHooked = true
    UIParent:HookScript("OnSizeChanged", function()
        if C_Timer and C_Timer.After then
            C_Timer.After(0, ScheduleBesideChatStayOnScreen)
        else
            ScheduleBesideChatStayOnScreen()
        end
    end)
end

FluxMicroMenu:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        InitializeMicroMenu()
    elseif event == "ADDON_LOADED" then
        if managedStartup and not Flux.loggedIn then return end
        EnsureChatSettleHooks()
        FixMicroButtonNotifications()
        if not FluxMicroMenu._startupReady then
            InitializeMicroMenu()
        else
            RequestDiscoveryRefresh()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if not FluxMicroMenu._startupReady then InitializeMicroMenu() end
        if FluxMicroMenu.needsUpdate then
            FluxMicroMenu.needsUpdate = false
            HijackButtons()
        end
    elseif event == "PLAYER_LEVEL_UP" or event == "PLAYER_ENTERING_WORLD"
        or event == "PLAYER_TALENT_UPDATE" or event == "ACTIVE_TALENT_GROUP_CHANGED" then
        if not FluxGameMenuBlocksMicroTaintWork() and FluxUpdateTalentMicroButtonPreDF then
            FluxUpdateTalentMicroButtonPreDF()
        end
        if event == "PLAYER_ENTERING_WORLD" then
            if not FluxMicroMenu._startupReady then InitializeMicroMenu() end
            RequestDiscoveryRefresh()
            ScheduleBesideChatStayOnScreen()
        end
    end
end)

SLASH_FLUXMICRO1 = "/fluxmicro"
SlashCmdList["FLUXMICRO"] = function(msg)
    msg = string.lower(msg or "")
    if msg == "gap" then
        print("FluxUI MicroMenu Gap Detection:")
        local gap = FluxGetMicroButtonTopGap()
        print("  Detected top gap: " .. gap .. " pixels")

        local testButtons = {"CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton"}
        for _, btnName in ipairs(testButtons) do
            local btn = _G[btnName]
            if btn then
                local btnGap = FluxDetectMicroButtonTopGap(btn)
                local left, right, top, bottom = btn:GetHitRectInsets()
                print("  " .. btnName .. ": gap=" .. btnGap .. ", hitrect top=" .. (top or 0))
            end
        end
    elseif msg == "resetorder" or msg == "reset order" then
        if FluxMicroMenuConfig and FluxMicroMenuConfig.ResetUnifiedOrderToDefault then
            FluxMicroMenuConfig:ResetUnifiedOrderToDefault()
            print("FluxUI MicroMenu: row order reset to default.")
        end
        if FluxMicroMenuConfigUI and FluxMicroMenuConfigUI.RefreshRows then
            FluxMicroMenuConfigUI:RefreshRows()
        end
    elseif msg == "resetall" or msg == "reset all" then
        if FluxMicroMenuConfig and FluxMicroMenuConfig.ResetMicroMenuToFactoryDefaults then
            FluxMicroMenuConfig:ResetMicroMenuToFactoryDefaults()
            print("FluxUI MicroMenu: reset to factory defaults (native = Account, minimap = Off).")
        end
        if FluxMicroMenuConfigUI and FluxMicroMenuConfigUI.RefreshRows then
            FluxMicroMenuConfigUI:RefreshRows()
        end
    elseif msg == "debug" then
        print("FluxUI MicroMenu Debug:")
        print("  Buttons found: " .. (#FluxMicroMenu.buttons or 0))
        if FluxGetMicroButtonLayoutInfo then
            local layout = FluxGetMicroButtonLayoutInfo()
            print("  Standard size: " .. layout.standardWidth .. "x" .. layout.standardHeight .. " (DF+ only)")
            print("  Default size: " .. layout.defaultWidth .. "x" .. layout.defaultHeight)
            print("  Native size: " .. layout.nativeWidth .. "x" .. layout.nativeHeight)
            print("  Spacing: " .. layout.spacing .. " (" .. (layout.clientVersion >= 10 and "tight" or "standard") .. ")")
            print("  Top gap: " .. (layout.topGap or 0))
            print("  Sizing policy: " .. (layout.clientVersion >= 10 and "Standardized" or "Native preserved"))
            print("  Client: " .. (layout.isClassicEra and "Classic Era" or "Retail"))
        end
        print("  Actual button sizes:")
        for i, btn in ipairs(FluxMicroMenu.buttons) do
            if btn then
                local name = btn:GetName() or ("Button" .. i)
                local w, h = btn:GetSize()
                print("    " .. i .. ". " .. name .. ": " .. w .. "x" .. h)
            end
        end
    else
        HijackButtons()
        print("FluxUI MicroMenu Updated. Commands: |cffcccccc/fluxmicro resetorder|r — default row order only; |cffcccccc/fluxmicro resetall|r — order + native Account + minimap Off.")
    end
end

