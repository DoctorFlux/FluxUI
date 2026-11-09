-- Flux vehicle seat indicator. Blizzard-shaped skin left of the durability
-- frame, sharing its top-left chrome clearance.
-- The stock VehicleSeatIndicator stays in place at alpha 0
-- so Edit Mode layout is not Hide()'d or reparented.

local addonName, ns = ...

local SEAT_SIZE = 25
local SKIN_SIZE = 128
local GAP = 4
local INDICATOR_SCALE = 0.7

local indicator
local buttons = {}
local currSkin
local hasPulsedPlayer

local function ForeverGamepadUI()
    local Flux = ns.Flux or _G.Flux
    local cap = Flux and (Flux.Cap or Flux.Capabilities)
    return cap and cap.IsForeverGamepadUI and cap.IsForeverGamepadUI() == true
end

local function IsSecret(v)
    if v == nil then
        return false
    end
    local fn = issecretvalue or IsSecretValue
    if not fn then
        return false
    end
    local ok, secret = pcall(fn, v)
    return ok and secret and true or false
end

local function PlainEqual(a, b)
    if IsSecret(a) or IsSecret(b) then
        return false
    end
    return a == b
end

local function ReapplyStockIndicatorMute()
    local stock = _G.VehicleSeatIndicator
    if stock and stock.SetAlpha then
        pcall(stock.SetAlpha, stock, 0)
    end
    if FluxVehicleSeats_UpdateAnchor then
        FluxVehicleSeats_UpdateAnchor()
    end
end

local function MuteStockIndicator()
    local stock = _G.VehicleSeatIndicator
    if not stock or stock._fluxSeatsMuted then
        return
    end
    stock._fluxSeatsMuted = true
    if stock.SetAlpha and not (InCombatLockdown and InCombatLockdown()) then
        pcall(stock.SetAlpha, stock, 0)
    end
    if stock.UnregisterAllEvents then
        pcall(stock.UnregisterAllEvents, stock)
    end
    if FluxRemoveFrameFromEditMode then
        FluxRemoveFrameFromEditMode(stock)
    else
        stock.ignoreFramePositionManager = true
    end
    if stock.HookScript and not stock._fluxSeatsAlphaHook then
        stock._fluxSeatsAlphaHook = true
        stock:HookScript("OnShow", function()
            -- Edit Mode's RefreshVehicleSeatIndicator shows this inside its pass.
            if FluxEditModeBusy and FluxEditModeBusy() then
                FluxAfterEditMode(ReapplyStockIndicatorMute)
                return
            end
            ReapplyStockIndicatorMute()
        end)
    end
end

local function EnsureButton(index)
    local button = buttons[index]
    if button then
        return button
    end
    button = CreateFrame("Button", "FluxVehicleSeatButton" .. index, indicator)
    button:SetSize(SEAT_SIZE, SEAT_SIZE)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Vehicles\\VehicleSeats")
    bg:SetTexCoord(0, 0.1953125, 0, 0.78125)
    button.BG = bg

    local function seatIcon(layer)
        local tex = button:CreateTexture(nil, layer)
        tex:SetSize(10, 10)
        tex:SetPoint("CENTER")
        tex:SetTexture("Interface\\Vehicles\\VehicleSeats")
        tex:Hide()
        return tex
    end
    button.PlayerIcon = seatIcon("ARTWORK")
    button.PlayerIcon:SetTexCoord(0.390625, 0.4609375, 0, 0.28125)
    button.AllyIcon = seatIcon("ARTWORK")
    button.AllyIcon:SetTexCoord(0.390625, 0.4609375, 0.3125, 0.59375)

    local pulse = button:CreateTexture(nil, "OVERLAY")
    pulse:SetSize(SEAT_SIZE, SEAT_SIZE)
    pulse:SetPoint("CENTER", -1, 0)
    pulse:SetTexture("Interface\\Vehicles\\VehicleSeats")
    pulse:SetTexCoord(0.1875, 0.3828125, 0, 0.78125)
    pulse:SetBlendMode("ADD")
    pulse:SetVertexColor(0.2, 0.4, 0.8)
    pulse:Hide()
    button.PulseTexture = pulse

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetSize(10, 10)
    highlight:SetPoint("CENTER")
    highlight:SetTexture("Interface\\Vehicles\\VehicleSeats")
    highlight:SetTexCoord(0.390625, 0.4609375, 0, 0.28125)
    highlight:SetAlpha(0.5)
    button.Highlight = highlight

    button:SetScript("OnClick", function(self, mouseButton)
        local seatIndex = self.virtualID
        if not seatIndex then
            return
        end
        if mouseButton == "RightButton" and CanEjectPassengerFromSeat and CanEjectPassengerFromSeat(seatIndex) then
            if not ForeverGamepadUI() and MenuUtil and MenuUtil.CreateContextMenu and EJECT_PASSENGER then
                MenuUtil.CreateContextMenu(self, function(_, rootDescription)
                    rootDescription:SetTag("MENU_VEHICLE_SEAT")
                    rootDescription:CreateButton(EJECT_PASSENGER, function()
                        EjectPassengerFromSeat(seatIndex)
                    end)
                end)
            elseif EjectPassengerFromSeat then
                EjectPassengerFromSeat(seatIndex)
            end
            return
        end
        if UnitSwitchToVehicleSeat then
            pcall(UnitSwitchToVehicleSeat, "player", seatIndex)
        end
    end)

    button:SetScript("OnEnter", function(self)
        if not self:IsEnabled() or not UnitVehicleSeatInfo then
            return
        end
        local ok, controlType, occupantName, serverName, _, canSwitchSeats = pcall(UnitVehicleSeatInfo, "player", self.virtualID)
        if not ok then
            return
        end
        if not IsSecret(occupantName) and not IsSecret(serverName) and serverName and serverName ~= "" and occupantName and FULL_PLAYER_NAME then
            occupantName = format(FULL_PLAYER_NAME, occupantName, serverName)
        end
        local function tip()
            if IsSecret(occupantName) or not occupantName or occupantName == "" then
                return
            end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(occupantName)
        end
        local using = UnitUsingVehicle and UnitUsingVehicle("player")
        if IsSecret(using) then
            using = true
        end
        if not using then
            self.Highlight:Hide()
            tip()
            return
        end
        local canSwitch = (not IsSecret(canSwitchSeats) and canSwitchSeats) and CanSwitchVehicleSeat and CanSwitchVehicleSeat()
        if not canSwitch or IsSecret(controlType) then
            self.Highlight:Hide()
            SetCursor(nil)
            tip()
            return
        end
        if not IsSecret(occupantName) and occupantName and occupantName ~= "" then
            self.Highlight:Hide()
            tip()
            return
        end
        self.Highlight:Show()
        if controlType == "Root" then
            SetCursor("Interface\\CURSOR\\Driver")
        elseif controlType == "Child" then
            SetCursor("Interface\\CURSOR\\Gunner")
        else
            SetCursor("Interface\\CURSOR\\vehichleCursor")
        end
    end)

    button:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        SetCursor(nil)
        if self.Highlight then
            self.Highlight:Hide()
        end
    end)

    buttons[index] = button
    return button
end

local function PulseButton(button)
    local pulse = button and button.PulseTexture
    if not pulse then
        return
    end
    pulse:Show()
    pulse:SetAlpha(0)
    if SetUpAnimation then
        local function pulseFunc(_, elapsed)
            return math.abs(math.sin(elapsed * 360))
        end
        SetUpAnimation(pulse, { totalTime = 2, updateFunc = "SetAlpha", getPosFunc = pulseFunc }, pulse.Hide)
        return
    end
    pulse:SetAlpha(1)
    if C_Timer and C_Timer.After then
        C_Timer.After(2, function()
            if pulse.Hide then
                pulse:Hide()
            end
        end)
    end
end

local function HideButtons()
    for i = 1, #buttons do
        buttons[i]:Hide()
    end
end

local function UpdateSeats()
    if not indicator or not currSkin or not UnitVehicleSeatInfo then
        return
    end
    local playerName
    if UnitName then
        local ok, name = pcall(UnitName, "player")
        if ok and not IsSecret(name) then
            playerName = name
        end
    end
    for i = 1, #buttons do
        local button = buttons[i]
        if button:IsShown() then
            local ok, _, occupantName = pcall(UnitVehicleSeatInfo, "player", button.virtualID)
            if not ok or not occupantName or IsSecret(occupantName) then
                button.PlayerIcon:Hide()
                button.AllyIcon:Hide()
            elseif playerName and PlainEqual(occupantName, playerName) then
                button.occupantName = occupantName
                button.PlayerIcon:Show()
                button.AllyIcon:Hide()
                if not hasPulsedPlayer then
                    PulseButton(button)
                    hasPulsedPlayer = true
                end
            else
                button.occupantName = occupantName
                button.PlayerIcon:Hide()
                button.AllyIcon:Show()
            end
        end
    end
end

local function Unload()
    currSkin = nil
    hasPulsedPlayer = false
    if indicator then
        if indicator.BackgroundTexture then
            indicator.BackgroundTexture:SetTexture(nil)
        end
        HideButtons()
        indicator:Hide()
    end
end

local function SetupVehicle(vehicleIndicatorID)
    if not indicator or not GetVehicleUIIndicator then
        return
    end
    if vehicleIndicatorID == currSkin then
        UpdateSeats()
        return
    end
    if not vehicleIndicatorID or vehicleIndicatorID == 0 then
        Unload()
        return
    end
    local backgroundTexture, numSeatIndicators = GetVehicleUIIndicator(vehicleIndicatorID)
    if not backgroundTexture or not numSeatIndicators or numSeatIndicators < 1 then
        Unload()
        return
    end
    currSkin = vehicleIndicatorID
    indicator.BackgroundTexture:SetTexture(backgroundTexture)
    indicator:SetSize(SKIN_SIZE, SKIN_SIZE)
    HideButtons()
    for i = 1, numSeatIndicators do
        if not GetVehicleUIIndicatorSeat then
            break
        end
        local virtualSeatIndex, xOffset, yOffset = GetVehicleUIIndicatorSeat(vehicleIndicatorID, i)
        local button = EnsureButton(i)
        button.virtualID = virtualSeatIndex
        button:ClearAllPoints()
        button:SetPoint("CENTER", indicator, "TOPLEFT", (xOffset or 0) * SKIN_SIZE, -(yOffset or 0) * SKIN_SIZE)
        button:Show()
    end
    indicator:Show()
    UpdateSeats()
    if FluxVehicleSeats_UpdateAnchor then
        FluxVehicleSeats_UpdateAnchor()
    end
end

function FluxVehicleSeats_UpdateAnchor()
    if not indicator then
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        indicator._fluxNeedsAnchor = true
        return
    end
    local durability = _G.FluxDurabilityFrame
    indicator:ClearAllPoints()
    if durability then
        indicator:SetPoint("TOPRIGHT", durability, "TOPLEFT", -GAP / INDICATOR_SCALE, 0)
    else
        indicator:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
    end
    indicator._fluxNeedsAnchor = nil
end

local function EnsureIndicator()
    if indicator then
        return indicator
    end
    indicator = CreateFrame("Frame", "FluxVehicleSeatIndicator", UIParent)
    indicator:SetSize(SKIN_SIZE, SKIN_SIZE)
    indicator:SetScale(INDICATOR_SCALE)
    indicator:SetFrameStrata("HIGH")
    indicator:SetFrameLevel(20)
    indicator:Hide()
    indicator.BackgroundTexture = indicator:CreateTexture(nil, "BACKGROUND")
    indicator.BackgroundTexture:SetAllPoints()
    FluxVehicleSeats_UpdateAnchor()
    return indicator
end

local function OnEvent(_, event, unit, ...)
    if event == "UNIT_ENTERED_VEHICLE" and unit == "player" then
        local vehicleIndicatorID = select(3, ...)
        SetupVehicle(vehicleIndicatorID)
    elseif event == "PLAYER_GAINS_VEHICLE_DATA" and unit == "player" then
        local vehicleIndicatorID = select(1, ...)
        SetupVehicle(vehicleIndicatorID)
    elseif event == "UNIT_ENTERING_VEHICLE" and unit == "player" then
        hasPulsedPlayer = false
    elseif event == "VEHICLE_PASSENGERS_CHANGED" then
        UpdateSeats()
    elseif event == "UNIT_EXITED_VEHICLE" and unit == "player" then
        Unload()
    elseif event == "PLAYER_LOSES_VEHICLE_DATA" and unit == "player" then
        Unload()
    elseif event == "PLAYER_ENTERING_WORLD" then
        MuteStockIndicator()
        FluxVehicleSeats_UpdateAnchor()
        local count = UnitVehicleSeatCount and UnitVehicleSeatCount("player")
        if not IsSecret(count) and count == 0 then
            Unload()
        end
    elseif event == "PLAYER_REGEN_ENABLED" and indicator and indicator._fluxNeedsAnchor then
        FluxVehicleSeats_UpdateAnchor()
    end
end

local driver = CreateFrame("Frame")
driver:SetScript("OnEvent", OnEvent)
local events = {
    "UNIT_ENTERED_VEHICLE",
    "PLAYER_GAINS_VEHICLE_DATA",
    "UNIT_ENTERING_VEHICLE",
    "VEHICLE_PASSENGERS_CHANGED",
    "UNIT_EXITED_VEHICLE",
    "PLAYER_LOSES_VEHICLE_DATA",
    "PLAYER_ENTERING_WORLD",
    "PLAYER_REGEN_ENABLED",
}
for i = 1, #events do
    pcall(driver.RegisterEvent, driver, events[i])
end

EnsureIndicator()
MuteStockIndicator()

_G.FluxVehicleSeats_UpdateAnchor = FluxVehicleSeats_UpdateAnchor
