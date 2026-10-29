--[[
    ExtraButtonSystem/CombatGrid/Grid.lua
    Core grid container framework for NonCombat Grid
    
    Compatible with all WoW versions via FluxAPICompat.lua
]]

-- Create namespace
FluxNonCombatGrid = FluxNonCombatGrid or {}
local Grid = FluxNonCombatGrid

-- Constants
Grid.DEFAULT_BUTTON_SIZE = 44
Grid.DEFAULT_SPACING = 2
Grid.DEFAULT_SCALE = 1 / 1.265
Grid.BUTTON_SLOT_SIZE_MULTIPLIER = 1.2
Grid.GRID_SEQ = 1

-- ============================================================================
-- GRID CREATION
-- ============================================================================

function Grid.New(parent, opts)
    parent = parent or UIParent
    opts = opts or {}
    
    local rows = math.max(1, tonumber(opts.rows) or 2)
    local cols = math.max(1, tonumber(opts.cols) or 2)
    local size = tonumber(opts.size) or Grid.DEFAULT_BUTTON_SIZE
    local spacing = tonumber(opts.spacing) or Grid.DEFAULT_SPACING
    local name = opts.name or ("FluxNonCombatGrid" .. Grid.GRID_SEQ)
    local scale = tonumber(opts.scale) or Grid.DEFAULT_SCALE
    
    Grid.GRID_SEQ = Grid.GRID_SEQ + 1
    
    -- Create container frame
    local gridFrame = CreateFrame("Frame", name, parent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    gridFrame:SetClampedToScreen(true)
    gridFrame:SetScale(scale)
    
    -- Calculate dimensions
    -- Note: This is an initial estimate, Relayout will resize
    local slotSize = size * Grid.BUTTON_SLOT_SIZE_MULTIPLIER
    local width = cols * slotSize + math.max(0, cols - 1) * spacing
    local height = rows * slotSize + math.max(0, rows - 1) * spacing
    gridFrame:SetSize(width, height)
    
    -- Grid object
    local grid = {
        Frame = gridFrame,
        Buttons = {},
        Rows = rows,
        Cols = cols,
        ButtonSize = size,
        SlotSize = slotSize,
        Spacing = spacing,
        Name = name,
        ColumnPriorities = {}, -- [button] = col_index
        ColumnGroups = {},     -- [button] = "healing"|"mana"|"bandage"|etc
        ButtonOrder = {},      -- [button] = sort_order
    }
    
    -- Apply Border if available
    if FluxBorder then
        FluxBorder:ApplyTo(gridFrame, -4, -4, -5, -4)
        FluxBorder:SetClassColor(gridFrame, 1, true)
    end
    
    -- ========================================================================
    -- METHODS
    -- ========================================================================
    
    -- Create a button in the grid
    function grid:CreateButton(config)
        config = config or {}
        local btnSize = config.size or self.ButtonSize
        
        -- Apply multiplier for visual consistency with NonCombatGrid
        local scaleMultiplier = Grid.BUTTON_SLOT_SIZE_MULTIPLIER
        local slotSize = btnSize * scaleMultiplier
        
        -- Slot frame (wrapper)
        local slotFrame = CreateFrame("Frame", nil, self.Frame)
        slotFrame:SetSize(slotSize, slotSize)
        
        local Flux = _G.Flux
        local ebs = Flux and Flux.EBS
        local btn
        if ebs and ebs.Widget and ebs.Widget.Create then
            local seq = Grid.GRID_SEQ
            Grid.GRID_SEQ = Grid.GRID_SEQ + 1
            btn = ebs.Widget.Create(slotFrame, {
                name = (self.Name or "FluxNonCombatGrid") .. "Btn" .. seq,
                kind = "extra",
                size = btnSize,
                skipScripts = true,
                showBorder = true,
                tooltip = true,
                macroText = false,
            })
        end
        
        if btn and btn.Widget then
            -- Scale/Position to match NonCombatGrid look
            btn.Widget:SetParent(slotFrame)
            btn.Widget:SetScale(scaleMultiplier)
            btn.Widget:ClearAllPoints()
            btn.Widget:SetPoint("CENTER", slotFrame, "CENTER", 0, 0)
            if slotFrame.SetClipsChildren then
                pcall(slotFrame.SetClipsChildren, slotFrame, false)
            end
            
            btn.SlotFrame = slotFrame
            if ebs.Style and ebs.Style.Apply then
                ebs.Style.Apply(btn, "class")
            elseif FluxButtonUtil and FluxButtonUtil.ApplyButtonStyle then
                FluxButtonUtil:ApplyButtonStyle(btn, "class")
            end
            -- skipScripts skips Extra-window drag/pickup. Same Extra press,
            -- checked, CD, glow, and reticle as Extra-window slots.
            if ebs.Widget and ebs.Widget.BindLockedExtraHost then
                if ebs.Widget.BindLockedExtraHost(btn) == false then
                    slotFrame:Hide()
                    error("Grid secure click setup incomplete")
                end
            else
                local Click = Flux and Flux.ButtonFX and Flux.ButtonFX.Click
                if Click and Click.Apply then
                    if Click.Apply(btn.Widget, { onDown = true }) == false then
                        slotFrame:Hide()
                        error("Grid secure click setup incomplete")
                    end
                end
            end

            table.insert(self.Buttons, btn)

            function btn:SetPlaceholder(icon, label)
                self.PlaceholderTexture = icon
                self.PlaceholderLabel = label
                if self.ClearAction then self:ClearAction() end
                self.PlaceholderTexture = icon
                self.PlaceholderLabel = label
                if self.WIcon and icon then
                    self.WIcon:SetTexture(icon)
                    self.WIcon:SetDesaturated(true)
                    self.WIcon:SetVertexColor(0.25, 0.25, 0.25)
                    self.WIcon:Show()
                end
                if ebs.Paint and ebs.Paint.Update then
                    ebs.Paint.Update(self)
                elseif ebs.Paint and ebs.Paint.UpdateEmpty then
                    ebs.Paint.UpdateEmpty(self)
                elseif self.UpdateTexture then
                    self:UpdateTexture()
                elseif self.FullRefresh then
                    self:FullRefresh()
                end
            end
            
            function btn:ClearPlaceholder()
                self.PlaceholderTexture = nil
                self.PlaceholderLabel = nil
                self.PlaceholderHideCount = nil
                if ebs.Paint and ebs.Paint.ClearCache then
                    ebs.Paint.ClearCache(self)
                end
                if self.WIcon then
                    if self.WIcon.SetDesaturated then
                        self.WIcon:SetDesaturated(false)
                    end
                    self.WIcon:SetVertexColor(1, 1, 1, 1)
                end
            end

            function btn:SetLocked(locked)
                self.ButtonLocked = locked
                if self.Widget then
                    if locked then
                        self.Widget:SetScript("OnDragStart", nil)
                        self.Widget:SetScript("OnReceiveDrag", nil)
                        self.Widget:SetScript("OnDragStop", nil)
                        if self.Widget.RegisterForDrag then self.Widget:RegisterForDrag() end 
                    end
                end
            end

            function btn:SetCount(count, opts)
                if not self.WCount then
                    return
                end
                if type(opts) == "table" and opts.live then
                    self._forcedCountLive = true
                    self._liveCountItemId = opts.itemId or self.ItemId or self.ActionValue
                else
                    self._forcedCountLive = nil
                    self._liveCountItemId = nil
                end
                if count == nil then
                    self._forcedCount = nil
                    self.WCount:Show()
                    self.WCount:SetText("")
                    return
                end
                local secret = false
                local S = _G.Flux and _G.Flux.Secrets
                if S and S.IsSecretValue then
                    local ok, v = pcall(S.IsSecretValue, count)
                    secret = ok and v and true or false
                elseif issecretvalue then
                    local ok, v = pcall(issecretvalue, count)
                    secret = ok and v and true or false
                end
                if secret then
                    self._forcedCount = count
                    self.WCount:Show()
                    self.WCount:SetText(count)
                    return
                end
                if count == false then
                    self._forcedCount = nil
                    self.WCount:Show()
                    self.WCount:SetText("")
                    return
                end
                -- Keep 0 on food / water / NC stacks. Paint.UpdateCount honors _forcedCount.
                self._forcedCount = count
                self.WCount:Show()
                self.WCount:SetText(tostring(count))
            end

            -- Widget.Create skipScripts still installs Extra/minimap hover
            -- (Action.OnEnter + highlight HookScript). Custom modules may
            -- SetScript OnEnter later; highlight hooks survive that.
            function btn:ShowTooltip()
                self.tooltipEnabled = true
                if ebs.Action and ebs.Action.OnEnter then
                    ebs.Action.OnEnter(self)
                end
            end

            function btn:OnEnter()
                if self.TooltipEnabled == false or self.tooltipEnabled == false then
                    return
                end
                if ebs.Action and ebs.Action.OnEnter then
                    ebs.Action.OnEnter(self)
                end
            end

            function btn:OnLeave()
                if ebs.Action and ebs.Action.OnLeave then
                    ebs.Action.OnLeave(self)
                elseif GameTooltip then
                    GameTooltip:Hide()
                end
            end

            function btn:FullRefresh()
                if ebs.Paint and ebs.Paint.Update then
                    ebs.Paint.Update(self)
                end
                if self.UpdateTextCount then
                    self:UpdateTextCount()
                end
            end

            if btn.Widget.EnableMouse then
                btn.Widget:EnableMouse(true)
            end
            
            -- Ensure Show/Hide works on the slot container
            function btn:Show()
                if self.SlotFrame then self.SlotFrame:Show() end
            end
            
            function btn:Hide()
                if self.SlotFrame then self.SlotFrame:Hide() end
            end
            
            -- Store priorities and column group
            self.ColumnPriorities[btn] = config.columnPriority or 1
            self.ColumnGroups[btn] = config.columnGroup
            self.ButtonOrder[btn] = config.order or #self.Buttons
            
            -- Initial layout
            self:Relayout()
            return btn
        else
            slotFrame:Hide()
            return nil
        end
    end

    -- Set button column priority (used by Hearth/Teleport modules after CreateButton)
    grid.SetButtonColumnPriority = function(self, btn, priority)
        if btn then
            self.ColumnPriorities[btn] = priority or 1
        end
    end

    -- Set button order within column
    grid.SetButtonOrder = function(self, btn, order)
        if btn then
            self.ButtonOrder[btn] = order or 1
        end
    end
    
    -- Enforce max 2 buttons per column: move overflow to columns with 1 button, or new columns
    local function EnforceMax2PerColumn(cols)
        local overflow = {} -- list of { btn, order }
        local singleButtonCols = {} -- list of priorities that have exactly 1 button
        
        for pri, btnList in pairs(cols) do
            table.sort(btnList, function(a, b)
                return (grid.ButtonOrder[a] or 0) < (grid.ButtonOrder[b] or 0)
            end)
            if #btnList > 2 then
                for i = 3, #btnList do
                    table.insert(overflow, { btn = btnList[i], order = grid.ButtonOrder[btnList[i]] or 0 })
                end
                cols[pri] = { btnList[1], btnList[2] }
            elseif #btnList == 1 then
                table.insert(singleButtonCols, pri)
            end
        end
        
        table.sort(singleButtonCols, function(a, b) return a > b end) -- Prefer rightmost first (higher number = lower priority)
        table.sort(overflow, function(a, b) return a.order < b.order end)
        
        local maxPri = 0
        for pri in pairs(cols) do
            maxPri = math.max(maxPri, pri)
        end
        local nextPriority = maxPri + 1
        
        local singleIdx = 1
        for _, ov in ipairs(overflow) do
            local targetPri
            if singleIdx <= #singleButtonCols then
                targetPri = singleButtonCols[singleIdx]
                singleIdx = singleIdx + 1
            else
                targetPri = nextPriority
                nextPriority = nextPriority + 1
                cols[targetPri] = {}
            end
            grid.ColumnPriorities[ov.btn] = targetPri
            if not cols[targetPri] then cols[targetPri] = {} end
            table.insert(cols[targetPri], ov.btn)
        end
    end
    
    -- Compute dynamic column priorities by columnGroup.
    -- Named pair groups (foodwater, hearthteleport) share a column when both are
    -- visible. Leftover single-button columns may merge with each other.
    local GROUP_ORDER = {
        hearthteleport = 0,
        mount = 1,
        foodwater = 2,
        consumables = 3,
        utility = 4,
        other = 99,
    }
    function grid:ComputeDynamicPriorities()
        local byGroup = {}
        for _, btn in ipairs(self.Buttons) do
            local isVisible = true
            if btn.SlotFrame then isVisible = btn.SlotFrame:IsShown() end
            if isVisible then
                local grp = self.ColumnGroups[btn]
                if not grp then
                    if btn.IsFoodButton or btn.IsWaterButton then
                        grp = "foodwater"
                    elseif btn.IsHearthButton or btn.IsTeleportPortalButton then
                        grp = "hearthteleport"
                    elseif btn.IsMountButton then
                        grp = "mount"
                    elseif btn.IsConsumableButton then
                        grp = "consumables"
                    elseif btn.IsUtilitySlotButton then
                        grp = "utility"
                    else
                        grp = "other"
                    end
                    self.ColumnGroups[btn] = grp
                end
                if not byGroup[grp] then byGroup[grp] = {} end
                table.insert(byGroup[grp], btn)
            end
        end

        -- Build column list: one column per group (max 2 buttons; overflow → extra cols)
        local columns = {}
        for grp, btns in pairs(byGroup) do
            table.sort(btns, function(a, b)
                return (self.ButtonOrder[a] or 0) < (self.ButtonOrder[b] or 0)
            end)
            local i = 1
            while i <= #btns do
                local chunk = { btns[i] }
                if i + 1 <= #btns then
                    chunk[2] = btns[i + 1]
                    i = i + 2
                else
                    i = i + 1
                end
                table.insert(columns, {
                    group = grp,
                    buttons = chunk,
                    count = #chunk,
                    sortKey = (GROUP_ORDER[grp] or 99),
                })
            end
        end

        -- Merge leftover single-button columns (e.g. Mount alone + Consumables alone)
        local multiCols, singleCols = {}, {}
        for _, col in ipairs(columns) do
            if col.count >= 2 then
                multiCols[#multiCols + 1] = col
            else
                singleCols[#singleCols + 1] = col
            end
        end
        table.sort(singleCols, function(a, b)
            return (a.sortKey or 99) < (b.sortKey or 99)
        end)

        local mergedSingles = {}
        local si = 1
        while si <= #singleCols do
            if si + 1 <= #singleCols then
                local a, b = singleCols[si], singleCols[si + 1]
                -- Utility slots stay in their own column(s); do not stack under mount/food.
                if a.group == "utility" or b.group == "utility" then
                    mergedSingles[#mergedSingles + 1] = singleCols[si]
                    si = si + 1
                else
                    local combined = {
                        group = "merged",
                        buttons = { a.buttons[1], b.buttons[1] },
                        count = 2,
                        sortKey = math.min(a.sortKey or 99, b.sortKey or 99),
                    }
                    table.sort(combined.buttons, function(x, y)
                        return (self.ButtonOrder[x] or 0) < (self.ButtonOrder[y] or 0)
                    end)
                    mergedSingles[#mergedSingles + 1] = combined
                    si = si + 2
                end
            else
                mergedSingles[#mergedSingles + 1] = singleCols[si]
                si = si + 1
            end
        end

        columns = {}
        for _, c in ipairs(multiCols) do columns[#columns + 1] = c end
        for _, c in ipairs(mergedSingles) do columns[#columns + 1] = c end

        -- Sort: paired columns first, then by group order
        table.sort(columns, function(a, b)
            if a.count ~= b.count then
                return a.count > b.count
            end
            return (a.sortKey or 99) < (b.sortKey or 99)
        end)

        for i, col in ipairs(columns) do
            for _, btn in ipairs(col.buttons) do
                self.ColumnPriorities[btn] = i
            end
        end
    end

    -- Consolidate single-button columns when multiple exist
    -- Priority 1: healing (Bandage, HealPotion, Healthstone) | Priority 2: mana (ManaPotion, ManaGem)
    -- Protect columns with 2+ buttons from being split
    function grid:ConsolidateColumns()
        if InCombatLockdown() then return end
        
        -- Group visible buttons by current column priority
        local cols = {}
        for _, btn in ipairs(self.Buttons) do
            local isVisible = true
            if btn.SlotFrame then isVisible = btn.SlotFrame:IsShown() end
            
            if isVisible then
                local colPri = self.ColumnPriorities[btn] or 1
                if not cols[colPri] then cols[colPri] = {} end
                table.insert(cols[colPri], btn)
            end
        end
        
        -- Enforce max 2 per column (move overflow to single-button cols or new cols)
        EnforceMax2PerColumn(cols)
        
        -- Build list of all columns with their button counts and original priority
        local columnData = {}
        for pri, btnList in pairs(cols) do
            -- Protect columns with 2+ buttons (healing column or mana column)
            local isProtected = (#btnList >= 2) or false
            table.insert(columnData, {
                priority = pri,
                buttonCount = #btnList,
                buttons = btnList,
                isProtected = isProtected
            })
        end
        
        -- Sort by original priority (ascending) - we'll process in reverse for right-to-left consolidation
        table.sort(columnData, function(a, b)
            return a.priority < b.priority
        end)
        
        -- Count single-button columns (excluding protected ones with 2 buttons)
        local singleButtonCount = 0
        for _, colData in ipairs(columnData) do
            if colData.buttonCount == 1 then
                singleButtonCount = singleButtonCount + 1
            end
        end
        
        -- Only consolidate if we have 2+ single-button columns
        if singleButtonCount < 2 then
            return -- No consolidation needed
        end
        
        -- Skip consolidation for a single column.
        if #columnData <= 1 then
            return
        end
        
        -- Reassign priorities: consolidate single-button columns while preserving order
        -- Strategy: Keep protected columns (2-button priority 2/3) at their original priority, reassign others
        -- Process in reverse order (right-to-left) for consolidation
        local usedPriorities = {}
        local pendingSingleButton = nil
        
        -- First pass: preserve protected columns (2-button priority 2/3) and other two-button columns
        for _, colData in ipairs(columnData) do
            if colData.isProtected then
                -- Protected columns: preserve them at their original priority (2 or 3)
                for _, btn in ipairs(colData.buttons) do
                    self.ColumnPriorities[btn] = colData.priority
                end
                usedPriorities[colData.priority] = true
            elseif colData.buttonCount == 2 then
                -- Two-button columns: find next available priority
                local nextPriority = 1
                while usedPriorities[nextPriority] do
                    nextPriority = nextPriority + 1
                end
                for _, btn in ipairs(colData.buttons) do
                    self.ColumnPriorities[btn] = nextPriority
                end
                usedPriorities[nextPriority] = true
            end
        end
        
        -- Second pass: consolidate single-button columns while maintaining relative order
        -- Pair adjacent single-button columns to minimize columns with 1 button
        local singleButtonCols = {}
        for i, colData in ipairs(columnData) do
            if colData.buttonCount == 1 then
                table.insert(singleButtonCols, {
                    data = colData,
                    index = i,
                    originalPriority = colData.priority
                })
            end
        end
        
        -- Pair adjacent single-button columns (only if they're next to each other in the sorted list)
        local i = 1
        while i <= #singleButtonCols do
            local current = singleButtonCols[i]
            local next = singleButtonCols[i + 1]
            
            -- Check if next exists and if they're adjacent (no other columns in between)
            if next and (next.index == current.index + 1) then
                -- They're adjacent, pair them
                local nextPriority = 1
                while usedPriorities[nextPriority] do
                    nextPriority = nextPriority + 1
                end
                self.ColumnPriorities[current.data.buttons[1]] = nextPriority
                self.ColumnPriorities[next.data.buttons[1]] = nextPriority
                usedPriorities[nextPriority] = true
                i = i + 2 -- Skip both
            else
                -- Not adjacent or last one, assign alone
                local nextPriority = 1
                while usedPriorities[nextPriority] do
                    nextPriority = nextPriority + 1
                end
                self.ColumnPriorities[current.data.buttons[1]] = nextPriority
                usedPriorities[nextPriority] = true
                i = i + 1
            end
        end
    end
    
    -- Coalesce multiple visibility-driven relayout requests (e.g. six CombatGrid
    -- scan callbacks firing on the same debounced bag pulse) into one layout pass.
    function grid:BeginLayout()
        self._layoutBatchDepth = (self._layoutBatchDepth or 0) + 1
    end

    function grid:EndLayout(flush)
        self._layoutBatchDepth = math.max(0, (self._layoutBatchDepth or 0) - 1)
        if self._layoutBatchDepth == 0 and self._layoutBatchPending and flush ~= false then
            self._layoutBatchPending = nil
            self:Relayout()
        end
    end

    function grid:ScheduleRelayout()
        if (self._layoutBatchDepth or 0) > 0 then
            self._layoutBatchPending = true
            return
        end
        if InCombatLockdown() then
            self._pendingRegenRelayout = true
            return
        end
        if self._relayoutScheduled then return end
        self._relayoutScheduled = true
        local function run()
            self._relayoutScheduled = nil
            if self and self.Relayout and not InCombatLockdown() then
                self:Relayout()
            end
        end
        if C_Timer and C_Timer.After then
            C_Timer.After(0, run)
        else
            run()
        end
    end

    -- Relayout buttons (Column-Major: Fill columns from bottom-up or top-down?)
    -- Layouts columns left-to-right. Rows bottom-to-top.
    function grid:Relayout()
        if (self._layoutBatchDepth or 0) > 0 then
            self._layoutBatchPending = true
            return
        end
        if InCombatLockdown() then
            self._pendingRegenRelayout = true
            return
        end
        self._pendingRegenRelayout = nil
        local startup = _G.Flux and _G.Flux.Startup
        if startup and startup.Count then startup.Count("layout_passes") end

        local bm = _G.FluxBindingMode
        if bm and bm.ShouldForceShowAllExtraSlots and bm:ShouldForceShowAllExtraSlots() then
            for _, btn in ipairs(self.Buttons) do
                if btn.SlotFrame then
                    -- Ammo is hidden for the whole binding session (EBV.Apply); never force-show here.
                    if not btn.IsAmmoDisplayButton then
                        btn.SlotFrame:Show()
                    end
                end
            end
            if self.Frame then self.Frame:Show() end
        end

        -- Always use group-aware layout so Food+Water and Hearth+Teleport stay paired
        self:ComputeDynamicPriorities()
        
        local btnSize = self.ButtonSize
        local slotSize = btnSize * Grid.BUTTON_SLOT_SIZE_MULTIPLIER
        local spacing = self.Spacing
        
        -- Group buttons by column priority
        local cols = {}
        for _, btn in ipairs(self.Buttons) do
            -- Visibilty check
            local isVisible = true
            if btn.SlotFrame then isVisible = btn.SlotFrame:IsShown() end
            
            if isVisible then
                local colPri = self.ColumnPriorities[btn] or 1
                if not cols[colPri] then cols[colPri] = {} end
                table.insert(cols[colPri], btn)
            end
        end
        
        -- Sort columns
        local sortedCols = {}
        for pri, list in pairs(cols) do
            table.insert(sortedCols, pri)
            -- Sort buttons within column by order
            table.sort(list, function(a, b) 
                return (self.ButtonOrder[a] or 0) < (self.ButtonOrder[b] or 0)
            end)
        end
        table.sort(sortedCols)
        
        -- Hide grid when no visible buttons; defer InfoFrame/UnifiedBorder update
        if #sortedCols == 0 then
            self:Hide()
            C_Timer.After(0, function()
                if FluxInfoFrame and FluxInfoFrame.UpdatePosition then FluxInfoFrame.UpdatePosition() end
                if FluxUnifiedBorder and FluxUnifiedBorder.UpdateBorder then FluxUnifiedBorder.UpdateBorder() end
            end)
            return
        end
        self:Show()
        C_Timer.After(0, function()
            if FluxInfoFrame and FluxInfoFrame.UpdatePosition then FluxInfoFrame.UpdatePosition() end
            if FluxUnifiedBorder and FluxUnifiedBorder.UpdateBorder then FluxUnifiedBorder.UpdateBorder() end
        end)
        
        -- For right-to-left layout: priority 3 (healing) on right, priority 1 (bandage) on left
        -- Don't reverse - keep sorted order (1, 2, 3) so priority 1 is leftmost, priority 3 is rightmost
        
        -- Position
        local maxRows = 0
        local maxCols = 0
        
        -- First pass: calculate dimensions
        local hasSingleButtonCol = false
        for colIdx, pri in ipairs(sortedCols) do
            local btnList = cols[pri]
            maxCols = colIdx
            maxRows = math.max(maxRows, #btnList)
            if #btnList == 1 then hasSingleButtonCol = true end
        end

        -- When any column has 1 button, use at least 2 rows for centering (so single button sits in middle)
        local effectiveRows = maxRows
        if hasSingleButtonCol and maxRows == 1 then
            effectiveRows = 2
        end

        -- Same X squeeze as FluxMainActionBar: slot width, spacing X, and widget face width.
        local xS = (FluxUILayoutSqueeze and FluxUILayoutSqueeze.GetActionBarHorizontalSqueezeFactor and FluxUILayoutSqueeze.GetActionBarHorizontalSqueezeFactor()) or 1
        local spacingX = spacing * xS
        local slotSizeX = slotSize * xS
        local sizeStepX = slotSizeX + spacingX
        local sizeStep = slotSize + spacing

        local totalGridHeight = slotSize + math.max(effectiveRows - 1, 0) * sizeStep
        
        for colIdx, pri in ipairs(sortedCols) do
            local btnList = cols[pri]
            
            -- Center single-button columns vertically within grid height
            local centerOffset = 0
            if #btnList == 1 then
                centerOffset = (totalGridHeight - slotSize) / 2
            end
            
            for rowIdx, btn in ipairs(btnList) do
                local x = (colIdx - 1) * sizeStepX
                local y = (rowIdx - 1) * sizeStep + centerOffset
                
                btn.SlotFrame:ClearAllPoints()
                btn.SlotFrame:SetSize(slotSizeX, slotSize)
                btn.SlotFrame:SetPoint("BOTTOMLEFT", self.Frame, "BOTTOMLEFT", x, y)
                -- Also ensure frame level logic if needed
                if btn.Widget then
                     btn.SlotFrame:SetFrameLevel(btn.Widget:GetFrameLevel() - 1)
                end
            end
        end
        
        -- Resize Frame (use effectiveRows when single-button cols need centering)
        if maxCols > 0 then
             local newW = maxCols * slotSizeX + math.max(0, maxCols - 1) * spacingX
             local newH = effectiveRows * slotSize + math.max(0, effectiveRows - 1) * spacing
             self.Frame:SetSize(newW, newH)
        end

        local scaleMultiplier = Grid.BUTTON_SLOT_SIZE_MULTIPLIER
        for _, btn in ipairs(self.Buttons) do
            if btn and btn.Widget then
                local faceW = btnSize * xS
                if btn.Widget.SetSize then
                    btn.Widget:SetSize(faceW, btnSize)
                end
                if btn.Widget.SetScale then
                    btn.Widget:SetScale(scaleMultiplier)
                end
                local Style = _G.Flux and _G.Flux.EBS and _G.Flux.EBS.Style
                if Style and Style.StampFace then
                    Style.StampFace(btn, faceW, btnSize)
                end
                if btn.IsLABButton and FluxCombatAssistedCombat and FluxCombatAssistedCombat.ApplyAppearance then
                    FluxCombatAssistedCombat.ApplyAppearance()
                end
                if Style and Style.RefreshSqueezeChrome then
                    Style.RefreshSqueezeChrome(btn, faceW, btnSize)
                elseif FluxButtonUtil and FluxButtonUtil.SyncFluxButtonLayerSizesToWidget then
                    FluxButtonUtil:SyncFluxButtonLayerSizesToWidget(btn)
                end
            end
            if btn and btn.SlotFrame and btn.SlotFrame.SetClipsChildren then
                -- Pre-DF Quickslot2 ring overhangs the slot; clipping hides it.
                local clip = xS < 1
                if Flux.Client and (Flux.Client.isAnyClassic or Flux.Client.isPostDF == false) then
                    clip = false
                end
                btn.SlotFrame:SetClipsChildren(clip)
            end
        end
    end
    do
        local origRelayout = grid.Relayout
        function grid:Relayout()
            local R = _G.Flux and _G.Flux.Perf and _G.Flux.Perf.Regen
            if R and R.Time then
                return R.Time("nc.Relayout", origRelayout, self)
            end
            return origRelayout(self)
        end
    end

    function grid:RefreshAllModules()
        local mods = {
            FluxCombatAssistedCombat,
            FluxCombatHealPotion,
            FluxCombatBandage,
            FluxCombatManaPotion,
            FluxCombatManaGem,
            FluxCombatHealthstone,
            FluxCombatAmmo,
        }
        for _, m in ipairs(mods) do
            if m and m.Update then
                m.Update()
            end
        end
    end
    
    -- Standard Show/Hide
    function grid:Show() self.Frame:Show() end
    function grid:Hide() self.Frame:Hide() end
    
    return grid
end

--- Reapply General → Appearance accent on NonCombat Grid frame + all FluxButton rings (called from FluxBorder:RefreshAppearanceDependents).
function FluxNonCombatGrid_ApplyAppearanceAccent()
    local grid = _G.FluxNonCombatAPI and _G.FluxNonCombatAPI.DefaultGrid
    if not grid then
        return
    end
    if FluxBorder and grid.Frame and FluxBorder.RefreshClassColor then
        FluxBorder:RefreshClassColor(grid.Frame)
    end
    local Flux = _G.Flux
    local ebs = Flux and Flux.EBS
    if grid.Buttons then
        for _, btn in ipairs(grid.Buttons) do
            if not btn then
            elseif ebs and ebs.Style and ebs.Style.Apply then
                ebs.Style.Apply(btn, "class")
            elseif FluxButtonUtil and FluxButtonUtil.ApplyButtonStyle then
                FluxButtonUtil:ApplyButtonStyle(btn, "class")
            end
        end
    end
end

--- Re-layout NonCombat Grid after extra-button visibility changes (column occupancy / stacking).
function Grid.RefreshAfterVisibilityChange()
    local API = _G.FluxNonCombatAPI
    local g = API and API.DefaultGrid
    if not g or not g.Relayout then
        return
    end
    local Timer = C_Timer
    if Timer and Timer.After then
        Timer.After(0, function()
            if g and g.Relayout then
                g:Relayout()
            end
        end)
    else
        g:Relayout()
    end
end

--- Alias used by FluxExtraButtonVisibility.NotifyChanged (V9 name).
Grid.RefreshAllAfterVisibilityChange = Grid.RefreshAfterVisibilityChange

_G.FluxNonCombatGrid = Grid
