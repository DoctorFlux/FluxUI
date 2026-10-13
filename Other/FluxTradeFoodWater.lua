--[[
    Other/FluxTradeFoodWater.lua
    Trade window buttons for quickly trading conjured food/water stacks
    
    Features:
    - Two buttons below trade window: "Trade Food" and "Trade Water"
    - Only shows for characters with conjure spells
    - Left-click: Adds 1 stack to trade window (prioritizes full stacks)
    - Right-click: Casts conjure food/water spell
    - Automatically excludes items already in trade window
    - Excludes mana gems (only trades food/water)
    
    Compatible with all WoW versions.
]]

FluxTradeFoodWater = FluxTradeFoodWater or {}
local Module = FluxTradeFoodWater

-- State
Module.foodButton = nil
Module.waterButton = nil
Module.eventFrame = nil
Module.containerFrame = nil -- Container frame that holds both buttons
Module.usedStacksInTrade = {} -- Track all used bag/slot pairs in current trade: {["bag:slot"] = true}

-- ============================================================================
-- TIMER COMPATIBILITY
-- ============================================================================

-- Timer compatibility helper (for older clients without C_Timer)
local function After(delay, callback)
    if C_Timer and C_Timer.After then
        C_Timer.After(delay, callback)
    else
        -- Fallback for older clients
        local frame = CreateFrame("Frame")
        local elapsed = 0
        frame:SetScript("OnUpdate", function(self, dt)
            elapsed = elapsed + dt
            if elapsed >= delay then
                self:SetScript("OnUpdate", nil)
                pcall(callback)
                self:Hide()
            end
        end)
    end
end

-- ============================================================================
-- COMPATIBILITY HELPERS
-- ============================================================================

local function GetContainerNumSlots(bag)
    if C_Container and C_Container.GetContainerNumSlots then
        return C_Container.GetContainerNumSlots(bag)
    elseif _G.GetContainerNumSlots then
        return _G.GetContainerNumSlots(bag)
    end
    return 0
end

local function GetContainerItemID(bag, slot)
    if C_Container and C_Container.GetContainerItemID then
        return C_Container.GetContainerItemID(bag, slot)
    elseif _G.GetContainerItemID then
        return _G.GetContainerItemID(bag, slot)
    end
    return nil
end

local function GetContainerItemLink(bag, slot)
    if C_Container and C_Container.GetContainerItemLink then
        return C_Container.GetContainerItemLink(bag, slot)
    elseif _G.GetContainerItemLink then
        return _G.GetContainerItemLink(bag, slot)
    end
    return nil
end

local function GetContainerItemInfo(bag, slot)
    if C_Container and C_Container.GetContainerItemInfo then
        return C_Container.GetContainerItemInfo(bag, slot)
    elseif _G.GetContainerItemInfo then
        local texture, itemCount, locked, quality, readable, lootable, itemLink, isFiltered, noValue, itemID = _G.GetContainerItemInfo(bag, slot)
        if texture then
            return {
                iconFileID = texture,
                stackCount = itemCount,
                isLocked = locked,
                quality = quality,
                isReadable = readable,
                hasLoot = lootable,
                hyperlink = itemLink,
                isFiltered = isFiltered,
                hasNoValue = noValue,
                itemID = itemID
            }
        end
    end
    return nil
end

local function PickupContainerItemCompat(bag, slot)
    if C_Container and C_Container.PickupContainerItem then
        C_Container.PickupContainerItem(bag, slot)
    elseif _G.PickupContainerItem then
        _G.PickupContainerItem(bag, slot)
    end
end

-- ============================================================================
-- ITEM DETECTION HELPERS
-- ============================================================================

-- Check if item is a mana gem (to exclude from food/water detection)
local function IsManaGem(itemId, itemLink)
    if not itemId then return false end
    
    local itemName = GetItemInfo(itemId)
    if itemName then
        local lowerName = itemName:lower()
        if lowerName:find("gem") and lowerName:find("mana") then
            return true
        end
    end
    
    -- Also check link text
    if itemLink then
        local linkName = itemLink:match("%[(.-)%]")
        if linkName then
            local lowerLink = linkName:lower()
            if lowerLink:find("gem") and lowerLink:find("mana") then
                return true
            end
        end
    end
    
    return false
end

-- Find conjured food/water items in bags (excluding gems)
local function FindConjuredFoodWater()
    local Best = _G.FluxConsumableBest
    local Classify = _G.FluxConsumableClassify
    local Inv = _G.FluxInv

    -- Prefer runtime best when it is conjured and owned.
    if Best and Best.GetBest then
        local foodId, waterId
        local food = Best.GetBest("food")
        if food and food.isConjured and food.itemID and (food.count or 0) > 0 then
            foodId = food.itemID
        end
        local water = Best.GetBest("water")
        if water and water.isConjured and water.itemID and (water.count or 0) > 0 then
            waterId = water.itemID
        end
        if foodId and waterId then
            return foodId, waterId
        end
        -- Fill missing axis by scanning owned unique items for conjured stacks.
        if Inv and Inv.Bags and Inv.Bags.GetUniqueItems and Classify and Classify.Classify then
            local unique = Inv.Bags.GetUniqueItems()
            for itemID, rec in pairs(unique) do
                if (rec.count or 0) > 0 then
                    local cls = Classify.Classify(itemID)
                    if cls and cls.isConjured then
                        if not foodId and cls.kind == "food" then
                            foodId = itemID
                        elseif not waterId and cls.kind == "water" then
                            waterId = itemID
                        end
                    end
                end
                if foodId and waterId then
                    break
                end
            end
        end
        if foodId or waterId then
            return foodId, waterId
        end
    end

    local Detection = _G.FluxItemDetection
    if Detection and Detection.FindBestFoodAndWater then
        local bestFood, bestWater = Detection.FindBestFoodAndWater()
        if bestFood then
            local link = select(2, GetItemInfo(bestFood))
            if IsManaGem(bestFood, link) then
                bestFood = nil
            elseif link and Detection.GetItemRestoreValues then
                local _, _, isConjured = Detection.GetItemRestoreValues(link)
                if not isConjured then
                    bestFood = nil
                end
            end
        end
        if bestWater then
            local link = select(2, GetItemInfo(bestWater))
            if IsManaGem(bestWater, link) then
                bestWater = nil
            elseif link and Detection.GetItemRestoreValues then
                local _, _, isConjured = Detection.GetItemRestoreValues(link)
                if not isConjured then
                    bestWater = nil
                end
            end
        end
        return bestFood, bestWater
    end
    return nil, nil
end

-- ============================================================================
-- TRADE WINDOW HELPERS
-- ============================================================================

-- Extract item ID from hyperlink
local function GetItemIdFromLink(itemLink)
    if not itemLink then return nil end
    -- Hyperlink format: |cff9d9d9d|Hitem:12345:0:0:0:0:0:0:0:0|h[Item Name]|h|r
    local itemId = itemLink:match("item:(%d+)")
    if itemId then
        return tonumber(itemId)
    end
    return nil
end

-- Get items currently in trade window
local function GetItemsInTradeWindow()
    local itemsInTrade = {}
    local MAX_TRADABLE_ITEMS = 6
    
    for i = 1, MAX_TRADABLE_ITEMS do
        local tradeButton = _G["TradePlayerItem" .. i .. "ItemButton"]
        if tradeButton and tradeButton.hasItem then
            local itemLink = GetTradePlayerItemLink and GetTradePlayerItemLink(i)
            if itemLink then
                local itemId = GetItemIdFromLink(itemLink)
                if itemId then
                    itemsInTrade[itemId] = (itemsInTrade[itemId] or 0) + 1
                end
            else
                -- Fallback: try to get item ID from button's item info
                local itemId = GetContainerItemID and GetContainerItemID(-1, i) -- Trade window uses bag -1
                if not itemId and C_TradeInfo and C_TradeInfo.GetPlayerTradeItem then
                    local itemInfo = C_TradeInfo.GetPlayerTradeItem(i)
                    if itemInfo and itemInfo.itemID then
                        itemId = itemInfo.itemID
                    end
                end
                if itemId then
                    itemsInTrade[itemId] = (itemsInTrade[itemId] or 0) + 1
                end
            end
        end
    end
    
    return itemsInTrade
end

-- Find available trade slot
local function GetAvailableTradeSlot()
    local MAX_TRADABLE_ITEMS = 6
    
    for i = 1, MAX_TRADABLE_ITEMS do
        local tradeButton = _G["TradePlayerItem" .. i .. "ItemButton"]
        if tradeButton and not tradeButton.hasItem then
            return i
        end
    end
    
    return nil
end

-- ============================================================================
-- STACK FINDING LOGIC
-- ============================================================================

-- Find all stacks of an item in bags, sorted by priority (full stacks first)
-- Excludes stacks that are already in the trade window (tracked in Module.usedStacksInTrade)
local function FindStacksForTrade(itemId)
    if not itemId then return {} end
    
    local stacks = {}
    local numBags = NUM_BAG_SLOTS or 4
    
    for bag = 0, numBags do
        local numSlots = GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            -- Skip if this bag/slot is already used in trade
            local key = bag .. ":" .. slot
            if not Module.usedStacksInTrade[key] then
                local slotItemId = GetContainerItemID(bag, slot)
                if slotItemId == itemId then
                    local info = GetContainerItemInfo(bag, slot)
                    if info then
                        local stackCount = info.stackCount or 1
                        local maxStackSize = 1
                        
                        -- Get max stack size
                        local itemName, _, _, _, _, _, _, _, _, _, _, _, _, _, maxStack = GetItemInfo(itemId)
                        if maxStack then
                            maxStackSize = maxStack
                        end
                        
                        local isFull = (stackCount >= maxStackSize)
                        
                        table.insert(stacks, {
                            bag = bag,
                            slot = slot,
                            itemId = itemId,
                            stackCount = stackCount,
                            maxStackSize = maxStackSize,
                            isFull = isFull
                        })
                    end
                end
            end
        end
    end
    
    -- Sort: full stacks first, then by stack count descending
    table.sort(stacks, function(a, b)
        -- First priority: full stacks
        if a.isFull ~= b.isFull then
            return a.isFull
        end
        -- Second priority: higher stack count
        return a.stackCount > b.stackCount
    end)
    
    return stacks
end

-- ============================================================================
-- TRADE OPERATIONS
-- ============================================================================

-- Add a stack to trade window
local function AddStackToTrade(itemId, isFood)
    if not itemId then return false end
    if not TradeFrame or not TradeFrame:IsShown() then return false end
    
    -- Find available stacks (automatically excludes stacks already marked as used)
    local stacks = FindStacksForTrade(itemId)
    
    if #stacks == 0 then return false end
    
    -- Use the best available stack
    local selectedStack = stacks[1]
    if not selectedStack then return false end
    
    -- Find available trade slot
    local tradeSlot = GetAvailableTradeSlot()
    if not tradeSlot then return false end
    
    -- Pick up the item and click the trade slot
    PickupContainerItemCompat(selectedStack.bag, selectedStack.slot)
    
    -- Click the trade slot
    local tradeButton = _G["TradePlayerItem" .. tradeSlot .. "ItemButton"]
    if tradeButton then
        -- Use secure click
        if tradeButton:IsVisible() then
            -- The item should already be on cursor from PickupContainerItem
            -- We need to click the trade slot to place it
            -- Use ClickTradeButton for secure action
            if ClickTradeButton then
                ClickTradeButton(tradeSlot)
            else
                -- Fallback: try to click the button directly
                tradeButton:Click()
            end
            
            -- Mark this stack as used in the current trade session
            local stackKey = selectedStack.bag .. ":" .. selectedStack.slot
            Module.usedStacksInTrade[stackKey] = true
            
            return true
        end
    end
    
    return false
end


-- ============================================================================
-- CONJURE SPELL CASTING
-- ============================================================================

-- Setup right-click conjure spell for a button using secure attributes
local function SetupRightClickConjure(btn, isFood)
    if not btn then return end
    if InCombatLockdown() then
        After(0.2, function() SetupRightClickConjure(btn, isFood) end)
        return
    end

    local Spells = _G.FluxInv and _G.FluxInv.Spells
    local primary, secondary
    if isFood then
        primary = Spells and Spells.GetPreferredFoodConjureSpell and Spells.GetPreferredFoodConjureSpell()
        secondary = Spells and Spells.GetSecondaryFoodConjureSpell and Spells.GetSecondaryFoodConjureSpell()
    else
        primary = Spells and Spells.GetPreferredWaterConjureSpell and Spells.GetPreferredWaterConjureSpell()
        secondary = Spells and Spells.GetSecondaryWaterConjureSpell and Spells.GetSecondaryWaterConjureSpell()
    end
    
    -- Clear existing right-click attributes
    btn:SetAttribute("type2", nil)
    btn:SetAttribute("macrotext2", nil)
    
    if primary then
        local macro
        if secondary and secondary ~= primary then
            -- Modifier casts secondary, plain right-click casts primary
            macro = string.format("/cast [mod] %s; %s", secondary, primary)
        else
            -- Only primary spell available
            macro = string.format("/cast %s", primary)
        end
        
        -- Set secure attributes for right-click (type2 = right mouse button)
        -- Note: SecureActionButtonTemplate handles clicks via SecureActionButton_OnClick
        -- which checks attributes before calling any OnClick scripts
        btn:RegisterForClicks("LeftButtonUp", "RightButtonUp", "LeftButtonDown", "RightButtonDown")
        btn:SetAttribute("type2", "macro")
        btn:SetAttribute("macrotext2", macro)
        
        -- Debug: Verify attributes are set
        -- print("Set secure attributes - type2:", btn:GetAttribute("type2"), "macro:", btn:GetAttribute("macrotext2"))
        
        -- Store for reference
        btn._primaryConjure = primary
        btn._secondaryConjure = secondary
    else
        -- No conjure spells available - clear attributes
        btn:SetAttribute("type2", nil)
        btn:SetAttribute("macrotext2", nil)
        btn._primaryConjure = nil
        btn._secondaryConjure = nil
    end
end

-- ============================================================================
-- BUTTON CREATION
-- ============================================================================

-- Create the trade buttons
function Module.CreateButtons()
    if Module.foodButton and Module.waterButton then return end
    if not TradeFrame then return end
    
    -- Create container frame to hold both buttons (for single border)
    if not Module.containerFrame then
        local container = CreateFrame("Frame", "FluxTradeFoodWaterContainer", TradeFrame)
        container:SetSize(260, 35) -- Width: 120 + 20 gap + 120, Height: 25 + 10 padding
        container:SetPoint("TOP", TradeFrame, "BOTTOM", 0, 5)
        
        -- Apply FluxBorder to container (single border around both buttons)
        if FluxBorder and FluxBorder.ApplyTo then
            FluxBorder:ApplyTo(container)
            FluxBorder:SetClassColor(container, 1, true) -- Class color border with backdrop
        end
        
        Module.containerFrame = container
    end
    
    -- Create Food button (combine UIPanelButtonTemplate with SecureActionButtonTemplate for secure right-click)
    if not Module.foodButton then
        local foodBtn = CreateFrame("Button", "FluxTradeFoodButton", Module.containerFrame, "UIPanelButtonTemplate,SecureActionButtonTemplate")
        foodBtn:SetSize(120, 25)
        foodBtn:SetText("Trade Food")
        foodBtn:SetPoint("LEFT", Module.containerFrame, "LEFT", 10, 0)
        
        -- Register for both left and right clicks (on press, not release)
        foodBtn:RegisterForClicks("LeftButtonDown", "RightButtonDown")
        
        -- Use OnMouseDown for left-click to trigger on press (avoids double triggering)
        foodBtn:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                local foodId = FindConjuredFoodWater()
                if foodId then
                    AddStackToTrade(foodId, true)
                end
            end
        end)
        
        -- Setup right-click conjure spell (uses secure attributes)
        -- Must be called AFTER button creation so secure template is ready
        SetupRightClickConjure(foodBtn, true)
        
        -- Add tooltip
        foodBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Trade Food", 1, 1, 1)
            GameTooltip:AddLine("Left-click: Add stack to trade", 0.8, 0.8, 0.8)
            GameTooltip:AddLine("Right-click: Conjure food", 0.8, 0.8, 0.8)
            GameTooltip:Show()
        end)
        foodBtn:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
        
        Module.foodButton = foodBtn
    end
    
    -- Create Water button (combine UIPanelButtonTemplate with SecureActionButtonTemplate for secure right-click)
    if not Module.waterButton then
        local waterBtn = CreateFrame("Button", "FluxTradeWaterButton", Module.containerFrame, "UIPanelButtonTemplate,SecureActionButtonTemplate")
        waterBtn:SetSize(120, 25)
        waterBtn:SetText("Trade Water")
        waterBtn:SetPoint("RIGHT", Module.containerFrame, "RIGHT", -10, 0)
        
        -- Register for both left and right clicks (on press, not release)
        waterBtn:RegisterForClicks("LeftButtonDown", "RightButtonDown")
        
        -- Use OnMouseDown for left-click to trigger on press (avoids double triggering)
        waterBtn:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                local _, waterId = FindConjuredFoodWater()
                if waterId then
                    AddStackToTrade(waterId, false)
                end
            end
        end)
        
        -- Setup right-click conjure spell (uses secure attributes)
        -- Must be called AFTER button creation so secure template is ready
        SetupRightClickConjure(waterBtn, false)
        
        -- Add tooltip
        waterBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Trade Water", 1, 1, 1)
            GameTooltip:AddLine("Left-click: Add stack to trade", 0.8, 0.8, 0.8)
            GameTooltip:AddLine("Right-click: Conjure water", 0.8, 0.8, 0.8)
            GameTooltip:Show()
        end)
        waterBtn:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
        
        Module.waterButton = waterBtn
    end
end

-- ============================================================================
-- VISIBILITY LOGIC
-- ============================================================================

-- Update button visibility
function Module.UpdateButtonVisibility()
    if not Module.foodButton or not Module.waterButton then return end
    
    local Spells = _G.FluxInv and _G.FluxInv.Spells
    local Detection = _G.FluxItemDetection
    local tradeOpen = TradeFrame and TradeFrame:IsShown()
    
    -- Check if character has conjure spells
    local hasConjureFood = (Spells and Spells.HasConjureFood and Spells.HasConjureFood())
        or (Detection and Detection.HasConjureFood and Detection.HasConjureFood())
        or false
    local hasConjureWater = (Spells and Spells.HasConjureWater and Spells.HasConjureWater())
        or (Detection and Detection.HasConjureWater and Detection.HasConjureWater())
        or false
    
    -- Check if character has conjured items
    local foodId, waterId = FindConjuredFoodWater()
    local hasFood = foodId ~= nil
    local hasWater = waterId ~= nil
    
    -- Show/hide container and buttons based on conditions
    local shouldShow = tradeOpen and ((hasConjureFood or hasFood) or (hasConjureWater or hasWater))
    
    if Module.containerFrame then
        if shouldShow then
            Module.containerFrame:Show()
        else
            Module.containerFrame:Hide()
        end
    end
    
    -- Show food button if: trade open AND (has conjure food spell OR has conjured food in bags)
    if tradeOpen and (hasConjureFood or hasFood) then
        if Module.foodButton then
            Module.foodButton:Show()
            -- Update right-click conjure spell setup
            SetupRightClickConjure(Module.foodButton, true)
        end
    else
        if Module.foodButton then
            Module.foodButton:Hide()
        end
    end
    
    -- Show water button if: trade open AND (has conjure water spell OR has conjured water in bags)
    if tradeOpen and (hasConjureWater or hasWater) then
        if Module.waterButton then
            Module.waterButton:Show()
            -- Update right-click conjure spell setup
            SetupRightClickConjure(Module.waterButton, false)
        end
    else
        if Module.waterButton then
            Module.waterButton:Hide()
        end
    end
end

-- ============================================================================
-- EVENT HANDLING
-- ============================================================================

-- Initialize the module
function Module.Initialize()
    if Module.eventFrame then return end
    
    -- Create event frame
    local eventFrame = CreateFrame("Frame")
    Module.eventFrame = eventFrame
    
    -- Create buttons
    Module.CreateButtons()
    
    -- Register events
    eventFrame:RegisterEvent("TRADE_SHOW")
    eventFrame:RegisterEvent("TRADE_UPDATE")
    eventFrame:RegisterEvent("TRADE_CLOSED")
    -- Only the coalesced delayed variant during trade; raw BAG_UPDATE fires per slot.
    eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
    eventFrame:RegisterEvent("SPELLS_CHANGED")
    
    -- Event handler
    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "TRADE_SHOW" or event == "TRADE_UPDATE" then
            Module.UpdateButtonVisibility()
        elseif event == "TRADE_CLOSED" then
            if Module.containerFrame then Module.containerFrame:Hide() end
            if Module.foodButton then Module.foodButton:Hide() end
            if Module.waterButton then Module.waterButton:Hide() end
            -- Clear used stacks tracking when trade closes
            Module.usedStacksInTrade = {}
        elseif event == "BAG_UPDATE" or event == "BAG_UPDATE_DELAYED" then
            -- Update visibility when bags change (items might have been conjured)
            if TradeFrame and TradeFrame:IsShown() then
                Module.UpdateButtonVisibility()
            end
        elseif event == "SPELLS_CHANGED" then
            -- Spellbook changed - might have learned conjure spells
            if TradeFrame and TradeFrame:IsShown() then
                -- Update right-click conjure spell setup
                if Module.foodButton then
                    SetupRightClickConjure(Module.foodButton, true)
                end
                if Module.waterButton then
                    SetupRightClickConjure(Module.waterButton, false)
                end
                Module.UpdateButtonVisibility()
            end
        end
    end)
    
    -- Initial update if trade window is already open
    if TradeFrame and TradeFrame:IsShown() then
        Module.UpdateButtonVisibility()
    end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

-- Initialize when addon loads
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "_FluxUI" or addonName == "_FLUXUI" then
        -- Wait a bit for ItemDetection to load
        After(0.5, function()
            Module.Initialize()
        end)
        initFrame:UnregisterEvent("ADDON_LOADED")
    end
end)

-- Also try to initialize if TradeFrame already exists
if TradeFrame then
    After(1.0, function()
        Module.Initialize()
    end)
end

-- Export
_G.FluxTradeFoodWater = Module


