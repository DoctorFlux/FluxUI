-- Postal category button count/geometry and Flux inventory attachment selection.
local checks = 0
local function check(ok, label) checks = checks + 1; assert(ok, label) end
local function Run(kind, expected)
	FluxMailDB = nil
	StaticPopupDialogs = {}
	ACCEPT, CANCEL = "Accept", "Cancel"
	local frames, buttons = {}, {}
	local function widget(name)
		local f = { events = {}, shown = true, name = name }
		function f:RegisterEvent(event) self.events[event] = true end
		function f:SetScript(script, fn) self[script] = fn end
		function f:SetSize() end
		function f:SetScale(value) self.scale = value end
		function f:GetHeight() return 36 end
		function f:GetName() return self.name end
		function f:SetPoint(...) self.point = { ... } end
		function f:ClearAllPoints() end
		function f:RegisterForClicks() end
		function f:SetShown(on) self.shown = on end
		function f:IsShown() return self.shown end
		function f:SetTexture(texture) self.texture = texture end
		f.icon = { SetTexture = function(_, texture) f.texture = texture end }
		frames[#frames + 1] = f
		if name and name:find("FluxMailCategory", 1, true) then buttons[#buttons + 1] = f end
		return f
	end
	CreateFrame = function(_, name) return widget(name) end
	UIParent, MailFrame, SendMailFrame = widget("UIParent"), widget("MailFrame"), widget("SendMailFrame")
	SendMailNameEditBox = { SetText = function(_, value) SendMailNameEditBox.text = value end }
	CursorHasItem = function() return false end
	HasSendMailItem = function() return false end
	ATTACHMENTS_MAX_SEND = 12
	NUM_BAG_SLOTS = 4
	LE_ITEM_BIND_ON_ACQUIRE = 1
	local popup
	StaticPopup_Show = function(key) popup = key end
	local attached = {}
	local client = { isEra = kind == "Era", isAnniversary = kind == "Anniversary",
		isMists = kind == "MoP", isRetail = kind == "Retail", isCamelot = kind == "Forever" }
	local ns = { Flux = {
		Client = client, Spell = { GetIcon = function() return 132000 end },
		Item = { GetInfo = function(id)
			local class, subclass, bind = 7, id == 2 and 6 or 5, id == 3 and 1 or 0
			return nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, class, subclass, bind
		end },
		Container = {
			GetNumSlots = function(bag) return bag == 0 and 3 or 0 end,
			GetItemInfo = function(_, slot) return { itemID = slot } end,
		},
		Mail = {
			IsEnabled = function() return true end,
			GetSetting = function(_, key) return key == "EnableBag0" end,
			OnSettingsChanged = function() end,
			AttachBagItem = function(bag, slot, category)
				attached[#attached + 1] = { bag, slot, category }
				return true
			end,
		},
	} }
	assert(loadfile("Mail/CategoryAttach.lua"))("_FluxUI", ns)
	local eventFrame
	for _, f in ipairs(frames) do if f.events.MAIL_SHOW then eventFrame = f; break end end
	eventFrame.OnEvent(eventFrame, "MAIL_SHOW")
	check(#buttons == expected, kind .. " category count")
	check(buttons[1].scale == 0.73, kind .. " category scale")
	check(buttons[1].point[1] == "TOPLEFT" and buttons[1].point[3] == "TOPRIGHT", kind .. " external column")
	buttons[1].OnClick(buttons[1], "LeftButton")
	check(#attached == (kind == "Era" and 2 or 1) and attached[1][2] == 1 and attached[1][3], kind .. " matching item attached")
	buttons[1].OnClick(buttons[1], "RightButton")
	check(popup == "FLUX_MAIL_CATEGORY_RECIPIENT", kind .. " recipient menu")
end
Run("Era", 2)
Run("Anniversary", 13)
Run("MoP", 15)
Run("Retail", 13)
Run("Forever", 13)
print("Flux mail category attach: " .. checks .. " checks passed")
