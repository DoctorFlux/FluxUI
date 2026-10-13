-- FluxRespec_UI_Rows.lua
-- Summary-row include checks and the Info Frame row.

FluxRespec = FluxRespec or {}
local R = FluxRespec
R.UI = R.UI or {}
local UI = R.UI
UI.Rows = UI.Rows or {}
local Rows = UI.Rows

local INFO_ICON = "Interface\\Icons\\INV_Misc_Note_01"

function Rows.AttachAll(rows)
    if not rows then
        return
    end
    if rows.consumables then
        UI.AttachSectionCheck(rows.consumables, "consumables",
            "When checked, Save records the consumable preset and Load switches to it. Unchecked leaves the saved list and your current list alone.")
    end
    if rows.talents then
        UI.AttachSectionCheck(rows.talents, "talents",
            "When checked, Save records talents / spec / loadout and Load applies them. Unchecked keeps the last saved build and leaves your current one.")
    end
    if rows.spellbook then
        UI.AttachSectionCheck(rows.spellbook, "utilitySlots",
            "When checked, Save records Extra Button utility slots and Load restores them.")
    end
    if rows.bindings then
        UI.AttachSectionCheck(rows.bindings, "spellBindings",
            "When checked, Save records Flux spell bindings and Load restores them. Sticky-across-Respec rows still survive.")
    end
    if rows.bars then
        UI.AttachSectionCheck(rows.bars, "bars",
            "When checked, Save records action bars (Classic) or stance-bar order (Retail) and Load restores them.")
    end
    if rows.infoFrame then
        UI.AttachSectionCheck(rows.infoFrame, "infoFrame",
            "When checked, Save records Info Frame pins plus FPS / durability / ping and Load restores them.")
    end
end

function Rows.RefreshAll(rows, profile)
    if not rows then
        return
    end
    UI.RefreshSectionCheck(rows.consumables, profile, "consumables")
    UI.RefreshSectionCheck(rows.talents, profile, "talents")
    UI.RefreshSectionCheck(rows.spellbook, profile, "utilitySlots")
    UI.RefreshSectionCheck(rows.bindings, profile, "spellBindings")
    UI.RefreshSectionCheck(rows.bars, profile, "bars")
    UI.RefreshSectionCheck(rows.infoFrame, profile, "infoFrame")
    UI.RefreshSectionCheck(rows.gear, profile, "equipment")
    UI.RefreshSectionCheck(rows.runes, profile, "runes")
end

function Rows.MakeInfoFrameRow(parent, makeRowFn)
    local row
    if type(makeRowFn) == "function" then
        row = makeRowFn(parent, 22)
    else
        row = CreateFrame("Frame", nil, parent)
        row:SetHeight(26)
    end
    if row.icon then
        row.icon:SetTexture(INFO_ICON)
    end
    if row.label then
        row.label:SetText("Info Frame:")
    end
    return row
end

function Rows.RefreshInfoFrame(row, profile)
    if not row then
        return
    end
    local text, tag = "—", nil
    if R.Includes and R.Includes.InfoFrameSummary then
        text, tag = R.Includes.InfoFrameSummary(profile)
    end
    if row.value then
        row.value:SetText(text or "—")
    end
    if row.tag then
        row.tag:SetText(tag or "")
        row.tag:SetShown(tag and tag ~= "")
    end
end

R.UI.Rows = Rows
