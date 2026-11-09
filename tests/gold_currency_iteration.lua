-- Production gold-bar update with native currency replies and widgets mocked.
-- Optional argument: alternate FluxStatusBar.lua for a matched baseline replay.
local source = arg[1] or "StatusBars/FluxStatusBar.lua"
local file = assert(io.open(source, "rb"))
local text = file:read("*a"); file:close()
local first = assert(text:find("local function UpdateGoldBar()", 1, true))
local last = assert(text:find("-- Gold Bar Interaction:", first, true))
local chunk = "local _goldLastSig, _goldFillConfigured\n"
    .. text:sub(first, last - 1):gsub("local function UpdateGoldBar", "function UpdateGoldBar", 1)
local checks, failures = 0, 0
local burstQueries, burstCompletions = 0, 0
local function check(ok, label)
    checks = checks + 1
    if not ok then failures = failures + 1; print("FAIL " .. label) end
end
local function record(id, quantity)
    return { currencyTypesID=id, quantity=quantity or id, iconFileID=1000+id }
end
local function rendered(rows)
    local out = ""
    for _, info in ipairs(rows) do
        out = out .. "   Q" .. info.quantity .. string.format("|T%s:0:0:2:0|t", info.iconFileID)
    end
    return out
end

local function fixture(label, modern)
    local e = setmetatable({}, {__index=_G}); e._G=e
    local s = { reads=0, updates=0, backgrounds=0, textWrites=0, suffixWrites=0,
        fillWrites=0, valueWrites=0, layouts=0, ledger=0, hits=0, money=12345,
        width=240, itemSig="77=2", pvp="", rows={}, queries={}, budget=64 }
    local function font(isSuffix)
        local f={}
        function f:SetText(value)
            self.value=value
            if isSuffix then s.suffixWrites=s.suffixWrites+1 else s.textWrites=s.textWrites+1 end
        end
        function f:GetText() return self.value end
        function f:Show() self.shown=true end
        function f:Hide() self.shown=false end
        return f
    end
    s.bar={text=font(),suffixText=font(true)}
    function s.bar:GetWidth() return s.width end
    function s.bar:SetStatusBarColor(...) s.color={...};s.fillWrites=s.fillWrites+1 end
    function s.bar:SetValue(value) s.value=value;s.valueWrites=s.valueWrites+1 end
    e.GoldBar=s.bar
    e.ApplyGoldBarBackgroundColor=function() s.backgrounds=s.backgrounds+1 end
    e.GetMoney=function() return s.money end
    e.FormatNumber=function(n) return "Q"..tostring(n) end
    e.FormatMoneyFull=function(n) return "FULL"..n end
    e.FormatMoneyCompact=function(n) return "SHORT"..n end
    e.GetGoldItemTrackSignature=function() return s.itemSig end
    e.FluxPVPTracking={GetTrackedPVPText=function() return s.pvp end}
    e.FluxItemCurrencyTracking={LayoutGoldItemHovers=function() s.layouts=s.layouts+1 end}
    e.FluxGoldLedger={OnAfterGoldBarUpdate=function() s.ledger=s.ledger+1 end}
    e.PositionGoldBarRegionHits=function() s.hits=s.hits+1 end
    e.issecretvalue=function(value) return value==s.secretID end
    if modern then
        e.C_CurrencyInfo={GetBackpackCurrencyInfo=function(index)
            s.reads=s.reads+1; s.inPass=s.inPass+1; s.queries[#s.queries+1]=index
            -- Bound the test's deliberately nonterminating API model, not production.
            if s.inPass>s.budget then error("fixture API budget exceeded") end
            return s.reply and s.reply(index) or s.rows[index]
        end}
    else
        e.C_CurrencyInfo={}
        e.GetCurrencyListSize=function() return #s.rows end
        e.GetCurrencyListInfo=function(index)
            s.reads=s.reads+1
            local r=s.rows[index]
            return r.name,r.header,r.expanded,false,r.watched,r.quantity,r.icon
        end
    end
    local loadFn, err
    if setfenv then
        loadFn,err=loadstring(chunk,"@gold_currency_iteration")
        if loadFn then setfenv(loadFn,e) end
    else loadFn,err=load(chunk,"@gold_currency_iteration","t",e) end
    assert(loadFn,err)()
    function s:update()
        self.inPass=0;self.updates=self.updates+1
        local ok,err=pcall(e.UpdateGoldBar)
        check(ok,label.." update terminates: "..tostring(err))
        return ok
    end
    function s:expectCurrency(value)
        check(self.bar.suffixText.value==value,label.." currency formatting/order retained")
        check(self.bar.suffixText.shown==(value~=""),label.." currency visibility retained")
        check(self.bar.text.value==(value=="" and "FULL" or "SHORT")..self.money,label.." money format retained")
    end
    function s:expectStableUI()
        local tw,sw,layout,ledger,hits=self.textWrites,self.suffixWrites,self.layouts,self.ledger,self.hits
        local bg=self.backgrounds
        self:update()
        check(self.textWrites==tw and self.suffixWrites==sw,label.." unchanged text avoids writes")
        check(self.layouts==layout and self.ledger==ledger and self.hits==hits,label.." unchanged layout/ledger/hits remain skipped")
        check(self.backgrounds==bg+1,label.." background/accent refresh still occurs")
    end
    return s,e
end

for _,client in ipairs({"Forever","Retail"}) do
    -- All valid entries, including more than native bag geometry currently fits.
    local s=fixture(client.."/long",true)
    for i=1,12 do s.rows[i]=record(i,i==2 and 0 or i*10) end
    s:update();s:expectCurrency(rendered(s.rows))
    check(s.reads==13,client.." no arbitrary three/six/frame-width cap")
    check(s.fillWrites==1 and s.valueWrites==1 and s.value==0,client.." gold fill configured once")
    s:expectStableUI()
    check(s.fillWrites==1 and s.valueWrites==1,client.." repeat does not reconfigure fill")
    s.rows[2].quantity=99;s:update();s:expectCurrency(rendered(s.rows))
    check(s.layouts==2 and s.ledger==2 and s.hits==2,client.." changed facts publish existing UI once")
    s.money=54321;s:update();s:expectCurrency(rendered(s.rows))
    s.itemSig="77=3";s:update()
    check(s.layouts==4,client.." tracked-item signature still refreshes layout")
    s.width=245;s:update();check(s.layouts==5,client.." width signature still refreshes layout")

    local many=fixture(client.."/large-valid-list",true)
    many.budget=128
    for i=1,96 do many.rows[i]=record(i) end
    many:update();many:expectCurrency(rendered(many.rows))
    check(many.reads==97,client.." distinct valid currencies have no arbitrary count cap")

    local empty=fixture(client.."/empty",true)
    empty:update();empty:expectCurrency("")
    check(empty.reads==1,client.." nil response stops immediately")
    empty.pvp=" PVP";empty:update();empty:expectCurrency(" PVP")

    local gap=fixture(client.."/nil-gap",true)
    gap.rows[1]=record(7);gap.rows[3]=record(9)
    gap:update();gap:expectCurrency(rendered({gap.rows[1]}))
    check(gap.reads==2,client.." nil gap preserves previous termination contract")

    -- Non-nil repeated replies must not grow strings forever on money/inventory pulses.
    local repeated=fixture(client.."/repeat-burst",true)
    local one=record(81,10)
    repeated.reply=function() return one end
    local done=0
    for i=1,100 do if repeated:update() then done=done+1 end end
    burstQueries=burstQueries+repeated.reads;burstCompletions=burstCompletions+done
    check(done==100,client.." every repeated-reply pulse completes")
    check(repeated.reads==200,client.." repeated identity requires only two reads per pass")
    repeated:expectCurrency(rendered({one}))
    check(repeated.layouts==1 and repeated.ledger==1,client.." repeated pulses preserve fingerprint skipping")

    local duplicate=fixture(client.."/changed-duplicate",true)
    duplicate.rows={record(1,5),record(2,6),record(1,999),record(4,7)}
    duplicate:update();duplicate:expectCurrency(rendered({duplicate.rows[1],duplicate.rows[2]}))
    check(duplicate.reads==3,client.." repeated ID stops even when quantity/icon differ")

    -- These are invalid records, not currencies to truncate from a valid list.
    for _,kind in ipairs({"missing","zero","negative","string","fraction","nan","infinity","secret"}) do
        local bad=fixture(client.."/"..kind,true)
        local id=kind=="zero" and 0 or kind=="negative" and -1 or kind=="string" and "12"
            or kind=="fraction" and 1.5 or kind=="nan" and (0/0)
            or kind=="infinity" and math.huge or kind=="secret" and 999 or nil
        if kind=="secret" then bad.secretID=id end
        local invalid={currencyTypesID=id,quantity=0,iconFileID=0}
        bad.reply=function() return invalid end
        bad:update();bad:expectCurrency("")
        check(bad.reads==1,client.." "..kind.." identity stops before rendering")
        local valid=record(44,2)
        bad.reply=function(index) return index==1 and valid or invalid end
        local prior=bad.reads
        bad:update();bad:expectCurrency(rendered({valid}))
        check(bad.reads-prior==2,client.." "..kind.." keeps the preceding valid currency")
    end
end

-- These pinned clients use the existing legacy API path, not the modern struct.
for _,client in ipairs({"Era","Anniversary","MoP"}) do
    local s=fixture(client.."/legacy",false)
    s.rows={{name="Header",header=true,expanded=true},{name="One",watched=true,quantity=12,icon=101},
        {name="Hidden",watched=false,quantity=88,icon=102},{name="Two",watched=true,quantity=0,icon=103}}
    local expected="   Q12|T101:0:0:2:0|t   Q0|T103:0:0:2:0|t"
    s:update();s:expectCurrency(expected)
    check(s.reads==4,client.." legacy list scans stay bounded by native size")
    s:expectStableUI()
    s.pvp=" PVP";s:update();s:expectCurrency(expected.." PVP")
end

local none,e=fixture("absent-currency-APIs",false)
e.C_CurrencyInfo=nil;e.GetCurrencyListSize=nil;e.GetCurrencyListInfo=nil
none:update();none:expectCurrency("")
check(none.reads==0,"clients without currency APIs retain money display")

print(string.format("gold currency iteration: %d checks, %d failures; repeated burst queries=%d completed=%d/200",
    checks,failures,burstQueries,burstCompletions))
if failures>0 then os.exit(1) end
