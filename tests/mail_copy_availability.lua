-- Real convenience module, mocked mail/UI APIs. No native latency or pixels certified.
local source = arg[1] or "Mail/Conveniences.lua"
local checks, failures = 0, 0
local totals = { visibleHeaders = 0, visibleBodies = 0, visibleInvoices = 0,
    hiddenReads = 0, disabledReads = 0 }
local function check(ok, label)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. label) end
end
local noop = function() end

local function fixture(client, provider)
    local e = setmetatable({}, { __index = _G }); e._G = e
    local s = { header = 0, bodyReads = 0, invoiceReads = 0, frames = {},
        body = "Message text", invoice = true, money = 0, cod = 0, items = 0,
        sender = "Sender", subject = "Subject", enabled = { CarbonCopy = true, Forward = true } }
    local label = client .. "/" .. provider
    local methods = {}
    for name in ("SetSize SetPoint SetNormalTexture SetFrameStrata EnableMouse SetMovable RegisterForDrag SetAllPoints SetColorTexture SetMultiLine SetAutoFocus SetFontObject SetTextInsets HighlightText SetFocus"):gmatch("%S+") do
        methods[name] = noop
    end
    local function widget(kind, name, parent)
        local w = setmetatable({ kind = kind, parent = parent, shown = true, hooks = {}, events = {} }, { __index = methods })
        s.frames[#s.frames + 1] = w
        if name then e[name] = w end
        return w
    end
    function methods:RegisterEvent(event) self.events[event] = true end
    function methods:SetScript(event, fn) self[event] = fn end
    function methods:HookScript(event, fn) self.hooks[event] = fn end
    function methods:IsShown() return self.shown end
    function methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
    function methods:SetShown(value) self.shown = value end
    function methods:Show() self.shown = true end
    function methods:Hide() self.shown = false end
    function methods:SetEnabled(value) self.enabled = value end
    function methods:SetText(value) self.text = value end
    function methods:CreateTexture() return widget("Texture", nil, self) end
    function methods:CreateFontString() return widget("FontString", nil, self) end
    e.CreateFrame = widget
    e.UIParent = widget("Frame")
    e.MailFrame = widget("Frame", nil, e.UIParent)
    e.OpenMailFrame = widget("Frame", nil, e.MailFrame)
    e.InboxFrame = { openMailID = 1 }
    e.GetMoney = function() return 100 end
    e.GetInboxHeaderInfo = function()
        s.header = s.header + 1
        return nil, nil, s.sender, s.subject, s.money, s.cod, nil, s.items
    end
    e.GetInboxText = function()
        s.bodyReads = s.bodyReads + 1
        return s.body, nil, nil, true, s.invoice
    end
    e.GetInboxInvoiceInfo = function()
        s.invoiceReads = s.invoiceReads + 1
        return "seller", "Potion", "Buyer", 1000, 1200, 20, 30
    end
    e.FROM, e.MAIL_SUBJECT_LABEL = "From:", "Subject:"
    e.ChatFontNormal = {}
    e.Syndicator = provider:find("syndicator", 1, true) and { API = {} } or nil
    e.Baganator = provider:find("baganator", 1, true) and { API = {} } or nil
    local mail = { IsEnabled = function(key) return s.enabled[key] ~= false end,
        OnSettingsChanged = function(fn) s.settingsChanged = fn end,
        Print = noop, FillDraft = function(_, subject, body) s.draft = { subject, body }; return true end }
    assert(loadfile(source, "t", e))("_FluxUI", { Flux = { Mail = mail } })
    local events
    for _, f in ipairs(s.frames) do if f.events.MAIL_SHOW then events = f; break end end
    local function event(name) events.OnEvent(events, name) end
    event("MAIL_SHOW") -- Initialize persistent controls outside measured updates.
    s.header, s.bodyReads, s.invoiceReads = 0, 0, 0
    for _ = 1, 100 do event("MAIL_INBOX_UPDATE") end
    totals.visibleHeaders = totals.visibleHeaders + s.header
    totals.visibleBodies = totals.visibleBodies + s.bodyReads
    totals.visibleInvoices = totals.visibleInvoices + s.invoiceReads
    check(s.header == 100 and s.bodyReads == 100 and s.invoiceReads == 0,
        label .. " visible availability uses one header/body and no invoice expansion")
    check(e.FluxMailCopyButton:IsShown() and e.FluxMailForwardTextButton:IsShown()
        and e.FluxMailForwardTextButton.enabled, "existing available controls retained")
    local text = mail.GetCopyText()
    check(text == "From: Sender\nSubject: Subject\n\nMessage text\n\nseller: Potion — Buyer\nAmount: 1000\nBuyout: 1200\nDeposit: 20\nFee: 30",
        "explicit copy retains complete invoice format")
    check(s.invoiceReads == 1, "copy requests invoice data once on demand")
    e.FluxMailCopyButton.OnClick()
    local edit
    for _, f in ipairs(s.frames) do if f.kind == "EditBox" then edit = f end end
    check(e.FluxMailCopyFrame:IsShown() and edit.text == text, "copy dialog receives fresh full text")
    s.body = "Changed message"; s.invoice = false
    check(mail.ForwardOpenText() and s.draft[1] == "Subject" and s.draft[2] == s.body,
        "forward action reads current body")
    for _, field in ipairs({ "money", "cod", "items" }) do
        s[field] = 1; event("MAIL_INBOX_UPDATE")
        check(not e.FluxMailForwardTextButton.enabled, "forward blocks " .. field)
        s[field] = 0
    end
    s.body, s.invoice = nil, true; event("MAIL_INBOX_UPDATE")
    check(e.FluxMailCopyButton:IsShown(), "invoice without body remains copyable")
    s.invoice = false; event("MAIL_INBOX_UPDATE")
    check(not e.FluxMailCopyButton:IsShown() and not e.FluxMailForwardTextButton:IsShown(), "missing body/invoice hides controls")
    s.body = ""; event("MAIL_INBOX_UPDATE")
    check(e.FluxMailCopyButton:IsShown(), "empty but present body preserves availability")
    s.enabled.CarbonCopy = false; s.settingsChanged("Modules", "CarbonCopy")
    check(not e.FluxMailCopyButton:IsShown() and e.FluxMailForwardTextButton:IsShown(), "independent module toggle retains Forward")
    e.MailFrame.shown = false -- Child's own shown flag remains set.
    s.header, s.bodyReads, s.invoiceReads = 0, 0, 0
    for _ = 1, 100 do event("MAIL_SHOW") end
    totals.hiddenReads = totals.hiddenReads + s.header + s.bodyReads + s.invoiceReads
    check(s.header == 0 and s.bodyReads == 0 and s.invoiceReads == 0,
        label .. " mailbox opening skips hidden-parent mail details")
    e.MailFrame.shown = true
    s.enabled.Forward = false; s.settingsChanged("Modules", "Forward")
    s.header, s.bodyReads, s.invoiceReads = 0, 0, 0
    for _ = 1, 50 do event("MAIL_INBOX_UPDATE") end
    totals.disabledReads = totals.disabledReads + s.header + s.bodyReads + s.invoiceReads
    check(s.header == 0 and s.bodyReads == 0 and s.invoiceReads == 0,
        label .. " disabled convenience features do no mail reads")
    s.enabled.CarbonCopy, s.enabled.Forward = true, true
    e.OpenMailFrame.hooks.OnShow(e.OpenMailFrame)
    check(e.FluxMailCopyButton:IsShown() and e.FluxMailForwardTextButton.enabled,
        "reveal uses current metadata and restored settings")
    e.OpenMailFrame.IsVisible = false; e.OpenMailFrame.shown = false
    local before = s.header + s.bodyReads + s.invoiceReads
    event("MAIL_SHOW")
    check(s.header + s.bodyReads + s.invoiceReads == before, "legacy shown fallback skips hidden mail")
    e.OpenMailFrame.shown = true; e.OpenMailFrame.hooks.OnShow(e.OpenMailFrame)
    check(e.FluxMailCopyButton:IsShown(), "legacy shown fallback restores copy availability")
    event("MAIL_CLOSED")
    check(not e.FluxMailCopyFrame:IsShown(), "mailbox close still dismisses copy dialog")
end

for _, client in ipairs({ "forever", "retail", "era", "anniversary", "mists" }) do
    for _, provider in ipairs({ "builtin", "syndicator", "baganator", "baganator+syndicator" }) do fixture(client, provider) end
end
print(string.format("mail copy availability: %d checks, %d failures; visible headers=%d bodies=%d invoices=%d hidden reads=%d disabled reads=%d",
    checks, failures, totals.visibleHeaders, totals.visibleBodies, totals.visibleInvoices, totals.hiddenReads, totals.disabledReads))
if failures > 0 then os.exit(1) end
