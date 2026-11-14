-- Source-derived pre-visit stock and physical-item prices. No native stock,
-- access, discounts or correctness of emulator-era stock are inferred here.
local checks, profiles = 0, 0
local function check(value, label) checks = checks + 1; assert(value, label) end
local root = os.getenv("FLUX_AH_ROOT") or "."
local cases = {
    { label="Era", flags={isEra=true}, profile="Vanilla", count=862, build="1.15.9.69722", vial=4, census=true },
    { label="Era alias", flags={isClassicEra=true}, profile="Vanilla", count=862, build="1.15.9.69722", vial=4 },
    { label="Anniversary", flags={isAnniversary=true}, profile="TBC", count=1708, build="2.5.6.68941", vial=4, census=true },
    { label="TBC alias", flags={isTBC=true}, profile="TBC", count=1708, build="2.5.6.68941", vial=4 },
    { label="Wrath", flags={isWrath=true,isClassic=true}, profile="Wrath", count=2180, build="3.4.3.58936", vial=4, census=true },
    { label="Cata", flags={isCata=true,isClassic=true}, profile="Cata", count=3013, build="4.4.2.60895", vial=20, census=true },
    { label="MoP", flags={isMists=true,isClassic=true}, profile="Mists", count=3005, build="5.5.4.68806", vial=20, census=true },
    { label="Forever", flags={isForever=true,isRetail=true}, profile="Forever", count=849, build="1.60.1.70888", vial=4, census=true },
    { label="Camelot alias", flags={isCamelot=true,isRetail=true}, profile="Forever", count=849, build="1.60.1.70888", vial=4 },
    { label="Retail", flags={isRetail=true,isMidnight=true}, profile="Retail", count=3710, priced=3693, build="12.1.5.70783", vial=20, census=true },
    { label="Ambiguous classic", flags={isClassic=true}, count=0 },
    { label="Unknown", flags={}, count=0 },
}
local function Load(path, env, ns)
    local chunk = assert(loadfile(root .. "/Inventory/Restock/Auction/" .. path .. ".lua", "t", env))
    if setfenv then setfenv(chunk, env) end
    return chunk("_FluxUI", ns)
end
for _, case in ipairs(cases) do
    profiles = profiles + 1
    local secret, original = {}, { marker={} }
    local env = setmetatable({FluxAuctionRestock=original}, {__index=_G}); env._G=env
    env.issecretvalue = function(value) return value == secret end
    local function Forbidden() error("catalog must not call native APIs, scanners, frames, timers or optional addons") end
    env.LibStub,env.CreateFrame,env.GetItemInfo,env.GetMerchantItemInfo,env.BuyMerchantItem=Forbidden,Forbidden,Forbidden,Forbidden,Forbidden
    env.C_Timer={After=Forbidden,NewTimer=Forbidden,NewTicker=Forbidden}
    local ns={Flux={Client=case.flags}}
    Load("FluxAuctionRestockVendorCatalogRetail",env,ns)
    check((original._VendorCatalogRetail ~= nil) == (case.profile == "Retail"), "Retail maps construct only for Retail, excluding Forever's Retail alias")
    Load("FluxAuctionRestockVendorCatalog",env,ns)
    check(env.FluxAuctionRestock==original and original.marker~=nil, "catalog preserves existing restock namespace")
    check(original._VendorCatalogRetail==nil, "temporary Retail handoff is released after selection")
    local c=original.VendorCatalog
    check(c.profile==case.profile and c.count==case.count, case.label.." selects its own stock source")
    check(c.pricedCount==(case.priced or case.count), "priced cardinality is distinct from stock cardinality")
    for _, id in ipairs({0,-1,1.5,math.huge,0/0,"not an ID",secret}) do
        check(c.Get(id)==nil and not c.Has(id) and c.GetTerms(id)==nil, "invalid/secret ID stays unknown across the public API")
    end
    check(c.Get(nil)==nil and not c.Has(nil) and c.GetTerms(nil)==nil, "nil ID stays unknown")
    if case.profile then
        local retail=case.profile=="Retail"
        check(c.source==(retail and "TrinityCore-TDB1210.26091" or "LibItemDB-v1.9.0"), "source identities do not conflate GPL Retail and MIT ItemDB data")
        check(c.archiveSHA256==(retail and "fc5513334d7534a19f533124a95910193c8150379e5ed8d0db3e547ac2c5a3f5" or "852b091101bf709f54026369abe240cd3060b8fe20b601f3a457209740693afa"), "actual pinned archive identity is exposed")
        check(c.metadata.clientBuild==case.build and #c.metadata.sourceSHA256==64 and #c.metadata.unitSourceSHA256==64, "map and unit facts retain exact client build and source SHA256")
        local price,profile,source=c.Get(17031)
        check(price==1000 and profile==case.profile and source==c.source and c.Has(17031), "Rune of Teleportation has standalone source facts before visiting a vendor")
        check(c.Get("17032")==2000, "Rune of Portals uses its actual neutral physical-item price")
        check(c.Get(3371)==case.vial, "vial price divides the selected client's raw bundle price")
        check(c.Get(117)==5 and c.Get(159)==(retail and 1 or 5), "food and water lookup uses bundle count rather than max-stack or sell-price multiplier")
        local raw,count=c.GetTerms(3371)
        check(raw==(retail and 400 or case.vial*5) and count==(retail and 20 or 5), "public exact terms retain raw vial price and vendor bundle count")
        if not retail then
            raw,count=c.GetTerms(2512)
            check(raw==10 and count==200 and c.Get(2512)==10/200, "bulk ammunition keeps fractional copper unit price and exact integer terms")
        else
            raw,count=c.GetTerms(30615)
            check(raw==16000 and count==3 and c.Get(30615)==16000/3, "Retail three-item bundle keeps exact terms without rounding")
            raw,count=c.GetTerms(63251)
            check(raw==33333 and count==5 and c.Get(63251)==33333/5, "Retail fractional copper price is not rounded")
            for _, id in ipairs({19484,32233,37198,61931,61935,61936,61937,61942,61958,62038,62039,62040,69887,69892,210695,56162,60405}) do
                local unknown,why,from=c.Get(id)
                check(c.Has(id) and unknown==nil and why=="Retail" and from==c.source and c.GetTerms(id)==nil, "known vendor stock with zero/missing source price stays stock-only")
            end
        end
        for _, id in ipairs({785,2450,2447,765,2589,17056}) do
            check(c.Get(id)==nil and not c.Has(id) and c.GetTerms(id)==nil, "limited herbs, loot cloth and feathers are not promoted from item BuyPrice alone")
        end
        if case.census then
            local stock,priced=0,0
            for id=1,c.metadata.maxItemID do
                local value,selected,why=c.Get(id)
                if c.Has(id) then stock=stock+1 end
                if value then
                    priced=priced+1
                    local numerator,denominator=c.GetTerms(id)
                    check(type(value)=="number" and value>0 and numerator>0 and numerator%1==0 and denominator>=1 and denominator%1==0 and value==numerator/denominator, "every priced source row normalizes verified positive integer terms to a physical-item price")
                    check(c.Has(id) and selected==case.profile and why==c.source, "every priced row retains selected stock membership and provenance")
                elseif c.Has(id) then
                    check(c.GetTerms(id)==nil, "unpriced/missing IDs cannot manufacture exact invoice terms")
                end
            end
            check(stock==case.count and priced==(case.priced or case.count), "complete public lookup census matches source stock and priced cardinalities")
            check(not c.Has(c.metadata.maxItemID+1), "no fallback row is invented beyond the selected source")
        end
    else
        check(c.metadata==nil and c.source==nil and c.Get(17031)==nil and not c.Has(3371), "unknown client flags do not borrow another client's stock or price")
    end
    env.FluxRestockSettings={Get=function() return {} end}
    Load("FluxAuctionRestockData",env,ns)
    check(original.VendorCatalog==c and original.marker~=nil, "Data loading preserves the early catalog owner")
end
do
    local env=setmetatable({}, {__index=_G});env._G=env
    Load("FluxAuctionRestockVendorCatalog",env,{Flux={Client={isRetail=true}}})
    local c=env.FluxAuctionRestock.VendorCatalog
    check(c.profile=="Retail" and c.count==0 and c.Get(17031)==nil and not c.Has(17031), "missing Retail data module fails closed rather than borrowing a legacy profile")
end
print(("Auction vendor catalog: %d checks PASS; %d client/alias profiles; native stock/access/discounts NOT RUN"):format(checks,profiles))
