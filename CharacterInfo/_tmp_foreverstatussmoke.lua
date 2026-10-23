-- lua CharacterInfo/_tmp_foreverstatussmoke.lua
-- Execute the actual Forever installer, native CharacterFrame show/hide, and
-- TextStatusBar methods. This checks isolation contracts, not WoW's taint VM.
local root = (arg[0]:match("^(.*)[/\\]") or ".") .. "/../"
local function Read(path)
    local f = assert(io.open(root .. path)); local s = f:read("*a"); f:close(); return s
end
local function Compile(s, env)
    if setfenv then local f = assert(loadstring(s)); setfenv(f, env); return f end
    return assert(load(s, "Forever status fixture", "t", env))
end
local native = "../__AddonsForRef/wow-ui-source-forever/Interface/AddOns/"
local characterSource = Read(native .. "Blizzard_UIPanels_Game/Camelot/CharacterFrame.lua")
local function Method(name, following)
    local start = assert(characterSource:find("function CharacterFrameMixin:" .. name .. "(", 1, true))
    local finish = assert(characterSource:find("\nfunction CharacterFrameMixin:" .. following .. "(", start, true))
    return characterSource:sub(start, finish - 1)
end
local env = setmetatable({}, { __index = _G }); env._G = env
local callbacks, frames, hooks, updates = {}, {}, 0, 0
local itemLevel = 12.34
local secret = {}
local function Forbidden() error("Flux touched native Character/status code") end
env.issecretvalue = function(v) return rawequal(v, secret) end
env.GetAverageItemLevel = function() return itemLevel, itemLevel end
env.Flux = { Client = { isCamelot = true } }
env.PAPERDOLL_STATCATEGORIES = { { unit = "player", categoryName = "General", stats = { { stat = "HEALTH" }, { stat = "POWER" } } } }
local originalStats = env.PAPERDOLL_STATCATEGORIES[1].stats
env.PAPERDOLL_STATINFO = { ITEMLEVEL = { updateFunc = Forbidden } }
local function Text()
    return { SetText = function(self, value) self.text = value end,
        SetFormattedText = function(self, fmt, value) self.text = string.format(fmt, value) end,
        SetPoint = function() end, Show = function(self) self.shown = true end,
        Hide = function(self) self.shown = false end }
end
env.CreateFrame = function(_, name, parent)
    local row = { parent = parent, name = name, events = {}, scripts = {} }
    function row:SetHeight(v) self.height = v end
    function row:SetPoint() end
    function row:CreateFontString() return Text() end
    function row:RegisterEvent(event) self.events[event] = true end
    function row:SetScript(key, fn) self.scripts[key] = fn end
    frames[#frames + 1] = row
    if name then env[name] = row end
    return row
end
env.CharacterStatsPaneScrollBox = { UpdateStats = function() updates = updates + 1 end }
env.hooksecurefunc = function() hooks = hooks + 1; Forbidden() end
env.FluxInfoFrame = {
    AfterCharacterShown = function(fn) callbacks[#callbacks + 1] = fn end,
    HookForeverScrollBoxStatFrame = function(row, key) assert(key == "itemLevel"); row.pinKey = key end,
}
local ns = { Flux = env.Flux, CharacterStats = { useRetailPaneHooks = true } }
Compile(Read("CharacterInfo/RetailPane.lua"), env)("_FluxUI", ns)
assert(ns.CharacterStats.InstallRetailPane())
local row = assert(env.FluxForeverItemLevelRow)
assert(row.parent == env.CharacterStatsPaneScrollBox and row.Value.text == "12.3" and row.pinKey == "itemLevel")
assert(env.PAPERDOLL_STATCATEGORIES[1].stats == originalStats and #originalStats == 2
    and originalStats[1].stat == "HEALTH" and originalStats[2].stat == "POWER", "Flux modified native stat categories")
assert(updates == 0 and hooks == 0, "installer entered or hooked native stats update")
assert(#callbacks == 1)
callbacks[1]()
assert(#frames == 1 and updates == 0 and hooks == 0, "open refresh modified native stats")
itemLevel = 17.89; row.scripts.OnEvent(row, "PLAYER_AVG_ITEM_LEVEL_UPDATE")
assert(row.Value.text == "17.9" and row.numericValue == itemLevel)
itemLevel = secret; row.scripts.OnEvent(row, "PLAYER_AVG_ITEM_LEVEL_UPDATE")
assert(row.Value.text == "" and row.numericValue == nil, "secret item level reached formatting/pin cache")

-- Character OnShow must still call all five ORIGINAL status bars, and OnHide
-- must unwind the locks. No error-swallowing handler replacements are installed.
env.Settings = { SetOnValueChangedCallback = function() end }
Compile(Read(native .. "Blizzard_TextStatusBar/TextStatusBar.lua"), env)()
local originalUpdate = env.TextStatusBarMixin.UpdateTextStringWithValues
env.GetCVar = function(name) return name == "statusTextDisplay" and "NUMERIC" or "1" end
env.BreakUpLargeNumbers = tostring
env.AbbreviateLargeNumbers = tostring
local function Bar()
    local bar = { TextString = Text(), LeftText = Text(), RightText = Text(), lockShow = 0, controlsShownState = true }
    for key, value in pairs(env.TextStatusBarMixin) do bar[key] = value end
    function bar:GetValue() return 123 end
    function bar:GetMinMaxValues() return 0, 456 end
    function bar:Show() self.shown = true end
    function bar:Hide() self.shown = false end
    return bar
end
local health, mana, alternate = Bar(), Bar(), Bar()
env.PlayerFrame_GetHealthBar = function() return health end
env.PlayerFrame_GetManaBar = function() return mana end
env.PlayerFrame_GetAlternatePowerBar = function() return alternate end
env.PetFrameHealthBar, env.PetFrameManaBar = Bar(), Bar()
env.StatusTrackingBarManager = { SetTextLocked = function() end }
env.PaperDollFrame = {}
env.FrameUtil = { RegisterFrameForEvents = function() end, UnregisterFrameForEvents = function() end }
env.UnitPVPName = function() return "Player" end
env.PlaySound, env.UpdateMicroButtons, env.MicroButtonPulseStop = function() end, function() end, function() end
env.InputUtil = { IsGamepadUIEnabled = function() return false end }
env.EventRegistry = { TriggerEvent = function() end }
env.SOUNDKIT = { IG_CHARACTER_INFO_OPEN = 1, IG_CHARACTER_INFO_CLOSE = 2 }
env.GetCVarBitfield = function() return true end
env.CharacterFrameMixin = {}
Compile("local characterFrameDisplayInfo = { Default = {} }\nlocal CharacterFrameEvents = {}\n"
    .. "local function ShouldShowExaltedPlusHelpTip() return false end\n"
    .. Method("OnShow", "OnHide") .. Method("OnHide", "Collapse"), env)()
local panel = { UpdateCharacterModeTabPortrait = function() end, RefreshRightPane = function() end,
    OnShow = env.CharacterFrameMixin.OnShow, OnHide = env.CharacterFrameMixin.OnHide }
for _ = 1, 3 do
    panel:OnShow()
    for _, bar in ipairs({ health, mana, alternate, env.PetFrameHealthBar, env.PetFrameManaBar }) do
        assert(bar.lockShow == 1 and bar.TextString.text == "123 / 456")
        assert(bar.UpdateTextStringWithValues == originalUpdate)
    end
    callbacks[1]()
    panel:OnHide()
    for _, bar in ipairs({ health, mana, alternate, env.PetFrameHealthBar, env.PetFrameManaBar }) do
        assert(bar.lockShow == 0 and bar.showNumeric == nil)
    end
end
assert(env.TextStatusBarMixin.UpdateTextStringWithValues == originalUpdate and updates == 0 and hooks == 0)
print("Forever Character status OK: no category injection/native refresh/hooks; owned ilvl + pins + equipment events; original Character show/hide and text methods")
