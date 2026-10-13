--[[
    ExtraButtonSystem/ExtraButtons/Categories.lua
    Category window creation and management
    Based on ExtraButtons.lua from old FluxExtraButtonSystem
]]

local addonName, ns = ...
local E = FluxExtraButtons
if not E.Categories then E.Categories = {} end
local C = E.Categories

-- Retail/Midnight/Forever dropped the MouseIsOver global; Classic still has it.
local function FrameMouseOver(frame)
    if not frame then
        return false
    end
    if frame.IsForbidden and frame:IsForbidden() then
        return false
    end
    if frame.IsMouseOver then
        local ok, over = pcall(frame.IsMouseOver, frame)
        if ok then
            return over and true or false
        end
    end
    if MouseIsOver then
        local ok, over = pcall(MouseIsOver, frame)
        if ok and over then
            return true
        end
    end
    return false
end

-- Pools
C.activeCategoryWindows = {}
C.reusableCategoryWindowsPool = {}
C.reusableCategoryHeadersPool = {}

-- Backdrop settings
local CATEGORY_WINDOW_BACKDROP_SETTINGS = {
    bgFile = nil,
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = E.WINDOW_PADDING_HORIZONTAL, right = E.WINDOW_PADDING_HORIZONTAL, top = E.WINDOW_PADDING_VERTICAL, bottom = E.WINDOW_PADDING_VERTICAL }
}

-- Initialize categories system
function C:Initialize()
    self.activeCategoryWindows = {}
    self.activeFrames = {}
end

-- Get color based on category scope
function C:GetScopeColor(scope)
    if not scope then return E.DEFAULT_NEUTRAL_COLOR end

    if scope == "character" or scope == "class" then
        return E.CLASS_COLOUR or E.DEFAULT_NEUTRAL_COLOR
    elseif scope == "realm" then
        -- A bit darker than normal, no tint color
        return {r = E.DEFAULT_NEUTRAL_COLOR.r * 0.7, g = E.DEFAULT_NEUTRAL_COLOR.g * 0.7, b = E.DEFAULT_NEUTRAL_COLOR.b * 0.7}
    elseif scope == "account" then
        -- No tint at all
        return E.DEFAULT_NEUTRAL_COLOR
    else
        return E.DEFAULT_NEUTRAL_COLOR
    end
end

-- Apply scope coloring to a category window
function C:ApplyScopeColoring(frame, scope)
    if not frame then return end

    -- Let FluxBorder handle all coloring for unified SOLID window appearance
    if FluxBorder and frame.FluxBorderFrame then
        if scope == "character" or scope == "class" then
            -- Use class color for character/class scopes - SOLID window panel
            local classColor = E.CLASS_COLOUR or E.DEFAULT_NEUTRAL_COLOR
            FluxBorder:SetBorderColor(frame, classColor.r, classColor.g, classColor.b, 1.0)  -- Fully opaque
            FluxBorder:SetBackdropColor(frame, classColor.r * 0.15, classColor.g * 0.15, classColor.b * 0.15, 1.0)  -- Fully opaque

            -- Header background matches the class color theme
            if frame.headerFrame and frame.headerFrame.background then
                frame.headerFrame.background:SetColorTexture(classColor.r * 0.12, classColor.g * 0.12, classColor.b * 0.12, 1.0)
            end
        elseif scope == "realm" then
            -- White text, no color tint - completely neutral
            FluxBorder:SetBorderColor(frame, 0.3, 0.3, 0.3, 1.0)  -- Neutral gray border
            FluxBorder:SetBackdropColor(frame, 0.05, 0.05, 0.05, 1.0)  -- Neutral dark background

            -- Header neutral
            if frame.headerFrame and frame.headerFrame.background then
                frame.headerFrame.background:SetColorTexture(0.08, 0.08, 0.08, 1.0)
            end
        elseif scope == "account" then
            -- Blizzard yellow/gold text, dark gray background
            FluxBorder:SetBorderColor(frame, 0.2, 0.2, 0.2, 1.0)  -- Dark gray border
            FluxBorder:SetBackdropColor(frame, 0.12, 0.12, 0.12, 1.0)  -- Darker gray background

            -- Header dark gray
            if frame.headerFrame and frame.headerFrame.background then
                frame.headerFrame.background:SetColorTexture(0.15, 0.15, 0.15, 1.0)
            end
        end
    else
        -- Fallback coloring if FluxBorder not available
        if scope == "character" or scope == "class" then
            local classColor = E.CLASS_COLOUR or E.DEFAULT_NEUTRAL_COLOR
            if frame.SetBackdropColor then
                frame:SetBackdropColor(classColor.r * 0.08, classColor.g * 0.08, classColor.b * 0.08, 0.95)
            end
            if frame.SetBackdropBorderColor then
                frame:SetBackdropBorderColor(classColor.r, classColor.g, classColor.b, 0.9)
            end
        else
            if frame.SetBackdropColor then
                frame:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
            end
            if frame.SetBackdropBorderColor then
                frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.9)
            end
        end
    end
end

-- Create a category window widget
function C:CreateCategoryWindow()
    local frame = CreateFrame("Frame", nil, E.UI.contentFrame, "BackdropTemplate")
    frame:SetSize(200, 100)

    -- Apply FluxBorder for unified window appearance (no separate backdrop)
    if FluxBorder then
        FluxBorder:ApplyTo(frame, -2, -2, -2, -2) -- Consistent border styling
        -- FluxBorder will handle both background and border colors with scope-based styling
    else
        -- Minimal fallback if FluxBorder not available
        frame:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            tile = true, tileSize = 16,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        frame:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    end

    -- Set window-like properties
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(100) -- Above regular UI elements
    
    -- Create header container (full-width window title bar spanning entire border area)
    local headerFrame = CreateFrame("Frame", nil, frame)
    headerFrame:SetHeight(E.HEADER_HEIGHT + 6) -- Taller for proper title bar appearance
    -- Position to span the full border area (accounting for FluxBorder -2 insets)
    headerFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", -2, 2)
    headerFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 2, 2)

    -- Header background (will be colored based on scope)
    local headerBg = headerFrame:CreateTexture(nil, "BACKGROUND")
    headerBg:SetAllPoints()
    headerBg:SetColorTexture(0.08, 0.08, 0.08, 1.0)  -- Default, will be overridden by scope coloring
    headerFrame.background = headerBg

    -- Subtle header border for definition
    local headerBorder = headerFrame:CreateTexture(nil, "BORDER")
    headerBorder:SetPoint("BOTTOMLEFT", headerFrame, "BOTTOMLEFT")
    headerBorder:SetPoint("BOTTOMRIGHT", headerFrame, "BOTTOMRIGHT")
    headerBorder:SetHeight(1)
    headerBorder:SetColorTexture(0.4, 0.4, 0.4, 0.8)
    headerFrame.border = headerBorder

    frame.headerFrame = headerFrame
    
    -- Helper function to create styled buttons (works across all clients)
    local function CreateStyledButton(parent, size, tooltip)
        local btn = CreateFrame("Button", nil, parent)
        btn:SetSize(size, size)

        -- No background - removed for clean appearance

        -- No custom highlight - let button icons handle their own highlighting

        if tooltip then
            btn:SetScript("OnEnter", function(btn)
                GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
                GameTooltip:SetText(tooltip)
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        end

        return btn
    end

    -- Collapse button (window minimize/maximize style)
    local collapseBtn = CreateFrame("Button", nil, headerFrame)
    collapseBtn:SetSize(E.CATEGORY_ACTION_BUTTON_SIZE + 4, E.CATEGORY_ACTION_BUTTON_SIZE + 4)
    collapseBtn:SetPoint("LEFT", headerFrame, "LEFT", 4, 0)  -- Positioned inside the border area

    collapseBtn:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
    collapseBtn:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
    local hl = collapseBtn:GetHighlightTexture()
    if hl then
        hl:SetAllPoints()
        hl:SetBlendMode("ADD")
        hl:SetAlpha(0.8)
    end

    -- Tooltip for collapse button
    collapseBtn:SetScript("OnEnter", function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
        GameTooltip:SetText("Toggle Category")
        GameTooltip:Show()
    end)
    collapseBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    collapseBtn:SetScript("OnClick", function()
        if InCombatLockdown() then return end  -- Block during combat
        if frame.categoryData then
            frame.categoryData.isCollapsed = not frame.categoryData.isCollapsed
            self:RefreshCategories()
        end
    end)
    frame.collapseBtn = collapseBtn
    
    -- Redesigned action buttons container - modern flat style
    local BUTTON_SIZE = 16  -- Slightly larger for better visibility
    local BUTTON_SPACING = 2  -- Comfortable spacing
    local numButtons = 5  -- Total buttons: up, down, add, delete, scope
    local totalWidth = (BUTTON_SIZE * numButtons) + (BUTTON_SPACING * (numButtons - 1))

    local actionsFrame = CreateFrame("Frame", nil, headerFrame)
    actionsFrame:SetSize(totalWidth, BUTTON_SIZE)
    actionsFrame:SetPoint("RIGHT", headerFrame, "RIGHT", -18, 0)  -- Adjusted for new header positioning
    -- Store button size for later use in positioning logic
    actionsFrame.buttonSize = BUTTON_SIZE
    actionsFrame.buttonSpacing = BUTTON_SPACING
    frame.actionsFrame = actionsFrame
    
    -- Label (enhanced window title style - clickable for editing)
    local label = headerFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalMed2")
    label:SetPoint("LEFT", collapseBtn, "RIGHT", 8, 0) -- Good spacing from collapse button
    label:SetPoint("RIGHT", actionsFrame, "LEFT", -6, 0) -- Proper spacing before action buttons
    label:SetText("Category")
    label:SetJustifyH("LEFT")
    label:SetWordWrap(false)
    label:SetNonSpaceWrap(false)
    label:SetMaxLines(1)
    label:EnableMouse(true)
    frame.label = label
    
    -- Edit box for renaming (click on label to show)
    local editBox = CreateFrame("EditBox", nil, headerFrame, "InputBoxTemplate")
    editBox:SetHeight(E.HEADER_HEIGHT - 4)
    editBox:SetPoint("LEFT", label)
    editBox:SetPoint("RIGHT", label)
    editBox:SetAutoFocus(false)
    editBox:SetMaxLetters(64)
    editBox:SetFontObject(GameFontNormalMed2)
    editBox:Hide()
    editBox:EnableMouse(true)
    
    -- Store the header reference for edit box callbacks
    headerFrame.ownerHeaderObjRef = frame
    
    -- Click on label to edit (like old version)
    label:SetScript("OnMouseDown", function(sL)
        local oH = sL:GetParent().ownerHeaderObjRef
        if not oH or InCombatLockdown() then return end
        
        -- Close any other active edit box
        if C.currentActiveEditBoxOwner and C.currentActiveEditBoxOwner ~= oH then
            local prevOwner = C.currentActiveEditBoxOwner
            if prevOwner.editBox:IsShown() then
                local newName = prevOwner.editBox:GetText():gsub("^%s+", ""):gsub("%s+$", "")
                if newName == "" then newName = prevOwner.originalLabelForEdit or "Category" end
                if prevOwner.categoryData then
                    prevOwner.categoryData.label = newName
                    prevOwner.categoryData.name = newName
                end
                prevOwner.label:SetText(newName)
                prevOwner.editBox:Hide()
                prevOwner.label:Show()
                prevOwner.editBox:ClearFocus()
            end
        end
        
        -- Start editing this label
        oH.originalLabelForEdit = oH.categoryData and oH.categoryData.label or "Category"
        oH.label:Hide()
        oH.editBox:SetText(oH.originalLabelForEdit)
        oH.editBox:Show()
        oH.editBox:SetFocus()
        C.currentActiveEditBoxOwner = oH
    end)
    
    -- Right-click on edit box to cancel
    editBox:SetScript("OnMouseDown", function(sEB, button)
        if button == "RightButton" then
            local oH = sEB:GetParent().ownerHeaderObjRef
            if not oH or InCombatLockdown() then return end
            if oH.categoryData then
                oH.categoryData.label = oH.originalLabelForEdit
                oH.categoryData.name = oH.originalLabelForEdit
            end
            oH.label:SetText(oH.originalLabelForEdit)
            sEB:Hide()
            oH.label:Show()
            sEB:ClearFocus()
            C.currentActiveEditBoxOwner = nil
        end
    end)
    
    editBox:SetScript("OnEnterPressed", function(sEB)
        local oH = sEB:GetParent().ownerHeaderObjRef
        if not oH then return end
        local newName = sEB:GetText():gsub("^%s+", ""):gsub("%s+$", "")
        if newName == "" then newName = oH.originalLabelForEdit or "New Category" end
        if oH.categoryData then
            oH.categoryData.label = newName
            oH.categoryData.name = newName
        end
        oH.label:SetText(newName)
        sEB:Hide()
        oH.label:Show()
        sEB:ClearFocus()
        C.currentActiveEditBoxOwner = nil
    end)
    
    editBox:SetScript("OnEscapePressed", function(sEB)
        local oH = sEB:GetParent().ownerHeaderObjRef
        if not oH then return end
        if oH.categoryData then
            oH.categoryData.label = oH.originalLabelForEdit
            oH.categoryData.name = oH.originalLabelForEdit
        end
        oH.label:SetText(oH.originalLabelForEdit)
        sEB:Hide()
        oH.label:Show()
        sEB:ClearFocus()
        C.currentActiveEditBoxOwner = nil
    end)
    
    editBox:SetScript("OnEditFocusLost", function(sEB)
        local oH = sEB:GetParent().ownerHeaderObjRef
        if not oH then return end
        if C.currentActiveEditBoxOwner == oH and not sEB:HasFocus() then
            local newName = sEB:GetText():gsub("^%s+", ""):gsub("%s+$", "")
            if newName == "" then newName = oH.originalLabelForEdit or "New Category" end
            if oH.categoryData then
                oH.categoryData.label = newName
                oH.categoryData.name = newName
            end
            oH.label:SetText(newName)
            sEB:Hide()
            oH.label:Show()
            C.currentActiveEditBoxOwner = nil
        end
    end)
    
    frame.editBox = editBox
    
    -- Apply counter-scaling to header elements
    if E.ApplyCategoryUIScale then
        E.ApplyCategoryUIScale(headerFrame)
        E.ApplyCategoryUIScale(label)
        E.ApplyCategoryUIScale(editBox)
    end
    
    -- Create modern flat-style action buttons with proper highlighting
    local function CreateModernActionButton(texture, tooltip, onClick, texCoords, customSize)
        local btnSize = customSize or BUTTON_SIZE
        local btn = CreateFrame("Button", nil, actionsFrame)
        btn:SetSize(btnSize, btnSize)
        -- Initial position will be set later in the show/hide logic

        -- No background - clean button appearance

        -- Icon texture
        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        icon:SetTexture(texture)
        if texCoords then
            icon:SetTexCoord(unpack(texCoords))
        end
        btn.icon = icon

        -- Modern highlight effect
        local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        highlight:SetBlendMode("ADD")
        highlight:SetAlpha(0.8)
        btn.highlight = highlight

        -- Tooltip
        if tooltip then
            btn:SetScript("OnEnter", function(btn)
                GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
                GameTooltip:SetText(tooltip)
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        end

        -- Click handler
        if onClick then
            btn:SetScript("OnClick", onClick)
        end

        return btn
    end

    -- Move Up button - back to original design
    frame.moveUpBtn = CreateModernActionButton(
        "Interface\\Buttons\\UI-Panel-CollapseButton-Up",
        "Move Category Up",
        function()
            if not InCombatLockdown() and frame.categoryData then
                self:MoveCategory(frame.categoryData.id, -1)
            end
        end
    )

    -- Move Down button - back to original design
    frame.moveDownBtn = CreateModernActionButton(
        "Interface\\Buttons\\UI-Panel-ExpandButton-Up",
        "Move Category Down",
        function()
            if not InCombatLockdown() and frame.categoryData then
                self:MoveCategory(frame.categoryData.id, 1)
            end
        end
    )

    -- Add button - prominent plus symbol
    frame.addBtn = CreateModernActionButton(
        "Interface\\Buttons\\UI-PlusButton-Up",
        "Add New Button",
        function()
            if not InCombatLockdown() and frame.categoryData and E.Buttons then
                E.Buttons:AddButtonToCategory(frame.categoryData)
            end
        end
    )

    -- Delete button - clear X symbol
    frame.deleteBtn = CreateModernActionButton(
        "Interface\\Buttons\\UI-Panel-MinimizeButton-Up",
        "Delete Category",
        function()
            if not InCombatLockdown() and frame.categoryData then
                StaticPopupDialogs["FLUX_DELETE_CATEGORY"] = {
                    text = "Delete category \"" .. (frame.categoryData.name or "Unknown") .. "\"?",
                    button1 = "Yes",
                    button2 = "No",
                    OnAccept = function()
                        self:DeleteCategory(frame.categoryData.id, frame.categoryData.scope)
                    end,
                    timeout = 0,
                    whileDead = true,
                    hideOnEscape = true,
                    preferredIndex = 3,
                }
                StaticPopup_Show("FLUX_DELETE_CATEGORY")
            end
        end
    )

    -- Edit Scope button - compact gear icon (smaller size)
    frame.editScopeBtn = CreateModernActionButton(
        "Interface\\Buttons\\UI-OptionsButton",
        "Change Category Scope",
        function(btn)
            if not InCombatLockdown() and frame.categoryData then
                C:ShowScopeDropdown(frame.categoryData, btn)
            end
        end,
        {0.15, 0.85, 0.15, 0.85},  -- Gear icon texture coordinates
        12  -- Smaller size for more compact appearance
    )
    
    -- Apply counter-scaling to action buttons and all elements
    if E.ApplyCategoryUIScale then
        E.ApplyCategoryUIScale(collapseBtn)
        E.ApplyCategoryUIScale(label)
        E.ApplyCategoryUIScale(editBox)
        E.ApplyCategoryUIScale(actionsFrame)
        E.ApplyCategoryUIScale(frame.moveUpBtn)
        E.ApplyCategoryUIScale(frame.moveDownBtn)
        E.ApplyCategoryUIScale(frame.addBtn)
        E.ApplyCategoryUIScale(frame.editScopeBtn)
        E.ApplyCategoryUIScale(frame.deleteBtn)
        -- Scale button backgrounds and icons
        if frame.moveUpBtn.bg then E.ApplyCategoryUIScale(frame.moveUpBtn.bg) end
        if frame.moveUpBtn.icon then E.ApplyCategoryUIScale(frame.moveUpBtn.icon) end
        if frame.moveDownBtn.bg then E.ApplyCategoryUIScale(frame.moveDownBtn.bg) end
        if frame.moveDownBtn.icon then E.ApplyCategoryUIScale(frame.moveDownBtn.icon) end
        if frame.addBtn.bg then E.ApplyCategoryUIScale(frame.addBtn.bg) end
        if frame.addBtn.icon then E.ApplyCategoryUIScale(frame.addBtn.icon) end
        if frame.deleteBtn.bg then E.ApplyCategoryUIScale(frame.deleteBtn.bg) end
        if frame.deleteBtn.icon then E.ApplyCategoryUIScale(frame.deleteBtn.icon) end
        if frame.editScopeBtn.bg then E.ApplyCategoryUIScale(frame.editScopeBtn.bg) end
        if frame.editScopeBtn.icon then E.ApplyCategoryUIScale(frame.editScopeBtn.icon) end
    end
    
    -- Button container (window content area with enhanced styling)
    local buttonContainer = CreateFrame("Frame", nil, frame)
    buttonContainer:SetPoint("TOPLEFT", headerFrame, "BOTTOMLEFT", 6, -E.HEADER_TO_BUTTONS_SPACING)
    buttonContainer:SetPoint("TOPRIGHT", headerFrame, "BOTTOMRIGHT", -6, -E.HEADER_TO_BUTTONS_SPACING)
    buttonContainer:SetHeight(50)

    -- No background - removed for clean appearance

    frame.buttonContainer = buttonContainer
    
    -- Store buttons list
    frame.buttonObjs = {}
    
    return frame
end

-- Get category window from pool
function C:GetCategoryWindowFromPool()
    local frame = table.remove(self.reusableCategoryWindowsPool)
    if frame then
        -- Reset button container visibility (will be set properly in RenderCategories)
        if frame.buttonContainer then
            frame.buttonContainer:Show()
        end
    end
    if not frame then
        frame = self:CreateCategoryWindow()
    end
    return frame
end

-- Return category window to pool
function C:ReturnCategoryWindowToPool(frame)
    if not frame then return end
    
    frame:Hide()
    frame:ClearAllPoints()
    frame.categoryData = nil
    
    -- Clear buttons
    if frame.buttonObjs then
        for _, btn in ipairs(frame.buttonObjs) do
            if E.Buttons and E.Buttons.ReturnButtonToPool then
                E.Buttons:ReturnButtonToPool(btn)
            end
        end
        wipe(frame.buttonObjs)
    end
    
    -- Hide button container
    if frame.buttonContainer then
        frame.buttonContainer:Hide()
    end
    
    table.insert(self.reusableCategoryWindowsPool, frame)
end

-- Create a new category
function C:CreateCategory(name, scope)
    scope = scope or "character"
    name = name or "New Category"
    
    -- Note: buttons are stored as separate entries in the flat entries table
    -- following the category entry, not nested inside category object
    local category = {
        type = "category",
        id = E:GenerateUniqueID(),
        name = name,
        label = name,
        scope = scope,
        isCollapsed = false,
    }
    
    -- Get entries table for scope
    local entriesTable = E:GetEntriesTableForScope(scope)
    if entriesTable then
        table.insert(entriesTable, category)
        -- Add an initial empty button entry after the category (like old version)
        table.insert(entriesTable, {type = "button"})
    end
    
    -- Add to display order
    if _FluxUI_CharSavedVars and _FluxUI_CharSavedVars.characterDisplayOrder then
        table.insert(_FluxUI_CharSavedVars.characterDisplayOrder, category.id)
    end
    
    self:RefreshCategories()
    
    return category
end

-- Delete a category (and all its buttons)
function C:DeleteCategory(categoryID, scope)
    local entriesTable = E:GetEntriesTableForScope(scope)
    if not entriesTable then return end
    
    -- Get category block range (category + all its buttons)
    local catStart, catEnd = E:GetCategoryBlockRange(entriesTable, categoryID)
    
    if catStart > 0 then
        -- Remove all entries in the category block (reverse order to maintain indices)
        for i = catEnd, catStart, -1 do
            table.remove(entriesTable, i)
        end
    end
    
    -- Remove from display order
    if _FluxUI_CharSavedVars and _FluxUI_CharSavedVars.characterDisplayOrder then
         for i, id in ipairs(_FluxUI_CharSavedVars.characterDisplayOrder) do
             if id == categoryID then
                 table.remove(_FluxUI_CharSavedVars.characterDisplayOrder, i)
                 break
             end
         end
    end
    
    self:RefreshCategories()
end

-- Move category in display order
function C:MoveCategory(categoryID, direction)
    if InCombatLockdown() then return end
    
    local displayOrder = _FluxUI_CharSavedVars and _FluxUI_CharSavedVars.characterDisplayOrder
    if not displayOrder then return end
    
    local currentIndex = nil
    for i, id in ipairs(displayOrder) do
        if id == categoryID then
            currentIndex = i
            break
        end
    end
    
    if not currentIndex then return end
    
    local newIndex = currentIndex + direction
    if newIndex < 1 or newIndex > #displayOrder then return end
    
    -- Swap (like old version)
    local tempID = displayOrder[currentIndex]
    displayOrder[currentIndex] = displayOrder[newIndex]
    displayOrder[newIndex] = tempID
    
    self:RefreshCategories()
end

-- Render categories
function C:RenderCategories(parentFrame)
    if not parentFrame then return end
    
    -- Check for combat lockdown
    if InCombatLockdown() then
        -- Queue the refresh for after combat
        C_Timer.After(0.2, function()
            if not InCombatLockdown() then
                C:RenderCategories(parentFrame)
        end
    end)
        return
    end
    
    -- Return existing windows to pool
    for _, catWindow in ipairs(self.activeCategoryWindows) do
        self:ReturnCategoryWindowToPool(catWindow)
    end
    self.activeCategoryWindows = {}
    
    -- Get all categories
    local allCats = E:GetAllCategoriesInOrder()
    
    -- Calculate content width like old version:
    -- scrollW - 30 (for scrollbar), with minimum for target columns
    local scrollW = 300
    if E.UI and E.UI.scrollFrame then
        scrollW = E.UI.scrollFrame:GetWidth() or 300
    end
    local TEMPLATE_SCROLLBAR_AREA_WIDTH = -30
    local buttonSize = E:GetDefaultButtonSize()
    local minW = (buttonSize * E.NUM_BUTTON_COLUMNS_TARGET) + (E.BUTTON_SPACING * (E.NUM_BUTTON_COLUMNS_TARGET - 1)) + (E.WINDOW_PADDING_HORIZONTAL * 2)
    local availableCW = math.max(scrollW + TEMPLATE_SCROLLBAR_AREA_WIDTH, minW)
    if availableCW < (buttonSize + 2 * E.WINDOW_PADDING_HORIZONTAL) then
        availableCW = buttonSize + 2 * E.WINDOW_PADDING_HORIZONTAL
    end
    parentFrame:SetWidth(availableCW)
    
    local yOffset = E.WINDOW_PADDING_VERTICAL
    
    for i, cat in ipairs(allCats) do
        local frame = self:GetCategoryWindowFromPool()
        frame.categoryData = cat
        frame:SetParent(parentFrame)
        frame:ClearAllPoints()
        -- Position with larger inset for window-like spacing
        frame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 15, -yOffset)
        frame:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -15, -yOffset)
        
        -- Apply scope-based coloring to the window
        self:ApplyScopeColoring(frame, cat.scope)

        -- Set label text and color based on scope with custom colors for realm/account
        local textR, textG, textB
        if cat.scope == "account" then
            -- Blizzard yellow/gold color for account scope
            textR, textG, textB = 1.0, 0.82, 0.0  -- Gold color
        elseif cat.scope == "realm" then
            -- White text for realm scope
            textR, textG, textB = 1.0, 1.0, 1.0  -- White
        else
            -- Use default scope colors for character/class
            textR, textG, textB = E:GetScopeColor(cat.scope)
        end
        frame.label:SetTextColor(textR, textG, textB)
        frame.label:SetText(cat.name or "Category")
        
        -- Update collapse button icon
        if cat.isCollapsed then
            frame.collapseBtn:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up")
        else
            frame.collapseBtn:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
        end
        
        -- Show/hide move buttons based on position and reposition for optimal layout
        local actionsFrame = frame.actionsFrame
        if not actionsFrame then return end -- Safety check

        local atTop = (i == 1)
        local atBottom = (i == #allCats)
        local buttonSize = actionsFrame.buttonSize or 16
        local buttonSpacing = actionsFrame.buttonSpacing or 2

        if frame.moveUpBtn then
            if atTop and atBottom then
                -- Single category - hide both move buttons
                frame.moveUpBtn:Hide()
            elseif atBottom then
                -- At bottom - move up button takes both positions (centered)
                frame.moveUpBtn:Show()
                frame.moveUpBtn:ClearAllPoints()
                frame.moveUpBtn:SetPoint("LEFT", actionsFrame, "LEFT", (buttonSize + buttonSpacing), 0) -- Takes second button position
                frame.moveUpBtn.icon:SetTexture("Interface\\Buttons\\UI-Panel-CollapseButton-Up")
            elseif atTop then
                -- At top - hide move up
                frame.moveUpBtn:Hide()
            else
                -- Normal position - show in first slot
                frame.moveUpBtn:Show()
                frame.moveUpBtn:ClearAllPoints()
                frame.moveUpBtn:SetPoint("LEFT", actionsFrame, "LEFT", 0, 0)
                frame.moveUpBtn.icon:SetTexture("Interface\\Buttons\\UI-Panel-CollapseButton-Up")
            end
        end

        if frame.moveDownBtn then
            if atTop and atBottom then
                -- Single category - hide both
                frame.moveDownBtn:Hide()
            elseif atTop then
                -- At top - move down button takes both positions (centered)
                frame.moveDownBtn:Show()
                frame.moveDownBtn:ClearAllPoints()
                frame.moveDownBtn:SetPoint("LEFT", actionsFrame, "LEFT", (buttonSize + buttonSpacing), 0) -- Takes second button position
                frame.moveDownBtn.icon:SetTexture("Interface\\Buttons\\UI-Panel-ExpandButton-Up")
            elseif atBottom then
                -- At bottom - hide move down
                frame.moveDownBtn:Hide()
            else
                -- Normal position - show in second slot
                frame.moveDownBtn:Show()
                frame.moveDownBtn:ClearAllPoints()
                frame.moveDownBtn:SetPoint("LEFT", actionsFrame, "LEFT", (buttonSize + buttonSpacing), 0)
                frame.moveDownBtn.icon:SetTexture("Interface\\Buttons\\UI-Panel-ExpandButton-Up")
            end
        end

        -- Position the remaining buttons (add, delete, edit scope) after the move buttons
        local nextButtonPos = 2 * (buttonSize + buttonSpacing)  -- After the two move button slots

        if frame.addBtn then
            frame.addBtn:ClearAllPoints()
            frame.addBtn:SetPoint("LEFT", actionsFrame, "LEFT", nextButtonPos, 0)
            nextButtonPos = nextButtonPos + buttonSize + buttonSpacing
        end

        if frame.editScopeBtn then
            frame.editScopeBtn:ClearAllPoints()
            frame.editScopeBtn:SetPoint("LEFT", actionsFrame, "LEFT", nextButtonPos, 0)
            -- Use smaller spacing for the compact edit scope button
            nextButtonPos = nextButtonPos + 12 + buttonSpacing  -- 12px for the smaller button
        end

        if frame.deleteBtn then
            frame.deleteBtn:ClearAllPoints()
            frame.deleteBtn:SetPoint("LEFT", actionsFrame, "LEFT", nextButtonPos, 0)
        end
        
        -- Calculate height based on collapsed state
        local buttonsHeight = 0

        -- Clear existing button references
        if frame.buttonObjs then
            wipe(frame.buttonObjs)
        else
            frame.buttonObjs = {}
        end

        if not cat.isCollapsed then
            -- Show button container and render buttons
            frame.buttonContainer:Show()

            if E.Buttons then
                buttonsHeight = E.Buttons:RenderButtonsForCategory(frame.buttonContainer, cat, E.BUTTONS_LEFT_INSET, 0)
                -- Store button references in frame
                local buttons = E:GetButtonsForCategory(cat)
                for _, btnData in ipairs(buttons) do
                    if btnData.buttonObj then
                        table.insert(frame.buttonObjs, btnData.buttonObj)
                    end
                end
            end
        else
            -- Hide button container when collapsed
            frame.buttonContainer:Hide()
        end

        -- Set frame height (different calculation for collapsed vs expanded)
        local totalHeight
        if cat.isCollapsed then
            -- Collapsed: minimal height with reduced padding, allow smaller than normal minimum
            totalHeight = E.HEADER_HEIGHT + E.HEADER_TOP_OFFSET_ADJUST + 2  -- Much smaller padding for collapsed
            frame:SetHeight(math.max(totalHeight, 25))  -- Smaller minimum for collapsed categories
        else
            -- Expanded: header + button spacing + buttons + padding
            totalHeight = E.HEADER_HEIGHT + E.HEADER_TO_BUTTONS_SPACING + E.HEADER_TOP_OFFSET_ADJUST + buttonsHeight + E.WINDOW_PADDING_VERTICAL * 2
            frame:SetHeight(math.max(totalHeight, 40))  -- Normal minimum for expanded categories
        end
        frame.buttonContainer:SetHeight(math.max(buttonsHeight, 1))
        
        frame:Show()
        table.insert(self.activeCategoryWindows, frame)
        
        yOffset = yOffset + frame:GetHeight() + 8 -- More spacing between windows
    end
    
    -- Update Add Category button position (position relative to last category)
    local lastCategoryFrame = nil
    if #self.activeCategoryWindows > 0 then
        lastCategoryFrame = self.activeCategoryWindows[#self.activeCategoryWindows]
    end
    if E.UI and E.UI.UpdateAddCategoryButtonPosition then
        E.UI:UpdateAddCategoryButtonPosition(yOffset, lastCategoryFrame)
    end
    
    -- Update content frame height (include space for Add Category button)
    local addBtnHeight = 30  -- Space for the Add New Category button
    local totalContentHeight = yOffset + addBtnHeight + E.WINDOW_PADDING_VERTICAL
    parentFrame:SetHeight(math.max(totalContentHeight, 100))
    
    -- Update scroll position if needed
    if E.UI and E.UI.scrollFrame then
        local scrollFrame = E.UI.scrollFrame
        local maxScroll = math.max(0, parentFrame:GetHeight() - scrollFrame:GetHeight())
        if scrollFrame:GetVerticalScroll() > maxScroll then
            scrollFrame:SetVerticalScroll(maxScroll)
        end
        if scrollFrame:GetVerticalScroll() < 0 then
            scrollFrame:SetVerticalScroll(0)
             end
        end
        
    -- Update toggle button icon
    if E.UI and E.UI.UpdateToggleButtonIcon then
        E.UI:UpdateToggleButtonIcon()
    end
end

-- Refresh categories display
function C:RefreshCategories()
    if E.UI and E.UI.contentFrame then
        self:RenderCategories(E.UI.contentFrame)
    end
end

-- Show scope dropdown (anchored to button)
function C:ShowScopeDropdown(categoryData, anchorButton)
    if not categoryData or not anchorButton then return end
    
    if not self.scopeDropdown then
        self:CreateScopeDropdown()
    end
    
    -- Toggle dropdown if already shown for same category
    if self.scopeDropdown:IsShown() and self.scopeDropdown.categoryData and 
       self.scopeDropdown.categoryData.id == categoryData.id then
        self.scopeDropdown:Hide()
        return
    end
    
    self.scopeDropdown.categoryData = categoryData
    self.scopeDropdown:ClearAllPoints()
    
    -- Get dropdown dimensions
    local dropdownWidth = self.scopeDropdown:GetWidth() or 100
    local dropdownHeight = self.scopeDropdown:GetHeight() or 84
    
    -- Get anchor button's parent frame (for relative positioning)
    local anchorParent = anchorButton:GetParent()
    if not anchorParent then
        anchorParent = UIParent
    end
    
    -- Get button position relative to its parent
    local buttonLeft = anchorButton:GetLeft()
    local buttonRight = anchorButton:GetRight()
    local buttonBottom = anchorButton:GetBottom()
    local buttonTop = anchorButton:GetTop()
    
    -- Get parent frame dimensions
    local parentLeft = anchorParent:GetLeft() or 0
    local parentRight = anchorParent:GetRight() or UIParent:GetWidth()
    local parentBottom = anchorParent:GetBottom() or 0
    local parentTop = anchorParent:GetTop() or UIParent:GetHeight()
    local parentWidth = parentRight - parentLeft
    local parentHeight = parentTop - parentBottom
    
    -- Calculate button position relative to parent
    local buttonRelLeft = (buttonLeft or 0) - parentLeft
    local buttonRelRight = (buttonRight or 0) - parentLeft
    local buttonRelBottom = (buttonBottom or 0) - parentBottom
    local buttonRelTop = (buttonTop or 0) - parentBottom
    
    -- Try positioning below button first (BOTTOMLEFT of dropdown to BOTTOMLEFT of button)
    local preferredPoint = "BOTTOMLEFT"
    local preferredRelativePoint = "TOPLEFT"
    local preferredX = 0
    local preferredY = 2  -- Small gap below button
    
    -- Check if dropdown would go off right edge of parent
    if buttonRelLeft + dropdownWidth > parentWidth then
        -- Try right-aligned (BOTTOMRIGHT of dropdown to BOTTOMRIGHT of button)
        preferredPoint = "BOTTOMRIGHT"
        preferredRelativePoint = "TOPRIGHT"
        preferredX = 0
    end
    
    -- Check if dropdown would go off bottom edge
    if buttonRelBottom - dropdownHeight - 2 < 0 then
        -- Show above button instead
        preferredPoint = "TOPLEFT"
        preferredRelativePoint = "BOTTOMLEFT"
        preferredY = -2  -- Small gap above button
    end
    
    -- Set position relative to anchor button
    self.scopeDropdown:SetPoint(preferredPoint, anchorButton, preferredRelativePoint, preferredX, preferredY)
    
    -- Update checkmarks
    local currentScope = categoryData.scope or "character"
    for _, row in ipairs(self.scopeDropdown.rows) do
        if row.scope == currentScope then
            row.check:Show()
        else
            row.check:Hide()
        end
    end
    
    self.scopeDropdown:Show()
end

-- Create scope dropdown
function C:CreateScopeDropdown()
    local dropdown = CreateFrame("Frame", "FluxExtraButtonsScopeDropdown", UIParent, "BackdropTemplate")
    dropdown:SetSize(100, 84)
    dropdown:SetFrameStrata("DIALOG")
    dropdown:SetClampedToScreen(true)
    dropdown:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    dropdown:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    dropdown:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    dropdown:Hide()
    
    -- Close when clicking elsewhere
    dropdown:SetScript("OnShow", function()
        dropdown:SetScript("OnUpdate", function()
            if not FrameMouseOver(dropdown) and IsMouseButtonDown("LeftButton") then
                dropdown:Hide()
            end
        end)
    end)
    dropdown:SetScript("OnHide", function()
        dropdown:SetScript("OnUpdate", nil)
    end)
    
    -- Scope options
    local scopes = {"character", "class", "realm", "account"}
    local scopeLabels = {
        character = "Character",
        class = "Class",
        realm = "Realm",
        account = "Account"
    }
    
    dropdown.rows = {}
    local yOffset = -6
    local rowHeight = 18
    
    for i, scope in ipairs(scopes) do
        local row = CreateFrame("Button", nil, dropdown)
        row:SetSize(90, rowHeight)
        row:SetPoint("TOP", dropdown, "TOP", 0, yOffset)
        row.scope = scope
        
        -- Checkmark
        local check = row:CreateTexture(nil, "ARTWORK")
        check:SetSize(12, 12)
        check:SetPoint("LEFT", row, "LEFT", 4, 0)
        check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        check:Hide()
        row.check = check
        
        -- Label
        local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("LEFT", row, "LEFT", 18, 0)
        label:SetText(scopeLabels[scope])
        row.label = label
        
        -- Highlight
        local highlight = row:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetColorTexture(1, 1, 1, 0.2)
        
        row:SetScript("OnClick", function()
            local catData = dropdown.categoryData
            if catData and scope ~= catData.scope then
                C:ChangeCategoryScope(catData, scope)
            end
            dropdown:Hide()
        end)
        
        table.insert(dropdown.rows, row)
        yOffset = yOffset - rowHeight
    end
    
    self.scopeDropdown = dropdown
    
    -- Apply counter-scaling
    if E.ApplyCategoryUIScale then
        E.ApplyCategoryUIScale(dropdown)
    end
end

-- Change category scope (move data between scope tables)
function C:ChangeCategoryScope(categoryData, newScope)
    if not categoryData or not newScope then return end
    local oldScope = categoryData.scope
    if oldScope == newScope then return end
    
    -- Get entries tables
    local oldEntriesTable = E:GetEntriesTableForScope(oldScope)
    local newEntriesTable = E:GetEntriesTableForScope(newScope)
    
    if not oldEntriesTable or not newEntriesTable then
        print("FluxExtraButtons: Could not change scope - table not found")
        return
    end
    
    -- Get category and its buttons from old table
    local catStart, catEnd = E:GetCategoryBlockRange(oldEntriesTable, categoryData.id)
    if catStart == -1 then
        print("FluxExtraButtons: Could not find category in old scope")
        return
    end
    
    -- Extract entries (category + buttons)
    local entriesToMove = {}
    for i = catStart, catEnd do
        table.insert(entriesToMove, oldEntriesTable[i])
    end
    
    -- Remove from old table (reverse order to maintain indices)
    for i = catEnd, catStart, -1 do
        table.remove(oldEntriesTable, i)
    end
    
    -- Update scope in category entry
    for _, entry in ipairs(entriesToMove) do
        if entry.type == "category" then
            entry.scope = newScope
    end
end

    -- Add to new table
    for _, entry in ipairs(entriesToMove) do
        table.insert(newEntriesTable, entry)
    end
    
    -- Refresh display
    self:RefreshCategories()
    
    print("FluxExtraButtons: Moved category to " .. newScope .. " scope")
end

-- Toggle all categories collapsed/expanded
function C:ToggleAll()
    if InCombatLockdown() then return end  -- Block during combat
    
    local allCats = E:GetAllCategoriesInOrder()
    
    -- Check if any are expanded
    local anyExpanded = false
    for _, cat in ipairs(allCats) do
        if not cat.isCollapsed then
            anyExpanded = true
            break
        end
    end
    
    -- Toggle all to opposite state
    for _, cat in ipairs(allCats) do
        cat.isCollapsed = anyExpanded
    end
    
    self:RefreshCategories()
end

-- Export
E.Categories = C
