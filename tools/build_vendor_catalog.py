"""Build/check standalone vendor data from pinned public source facts.

Pass the pinned ItemDB ZIP. Compact exhaustive unit facts and Retail source facts
are in tools/data; --retail-source-dir also validates original Retail evidence,
SQL/proof/source files. No network, installation or client/settings access.
Only selected-client maps are constructed at runtime. Separate MIT/GPL notices
retain source scope; no ItemDB runtime or engine implementation is bundled.
"""
import argparse
import hashlib
import json
import pathlib
import re
import zipfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
RELEASE = "LibItemDB-v1.9.0"
URL = "https://www.curseforge.com/wow/addons/libitemdb/files/9580874"
DOWNLOAD = "https://mediafilez.forgecdn.net/files/9580/874/ItemDB-ItemDB-v1.9.0.zip"
ARCHIVE_SHA = "852b091101bf709f54026369abe240cd3060b8fe20b601f3a457209740693afa"
UNITS_SHA = "12a63943be34629dacdad2e9823e636e48eb36cc1e7bcc98c8c9c4e935811e67"
RETAIL_SHA = "8bf14c546b2bb8087c73986364d4975d7cdc366e5f5c16d1b3fbb765af717b0d"
TC_PIN = "01df6f3e1f66c9df867bceb27c7cdc7c4ecf737c"
TC_LICENSE_SHA = "3e4282f9203a67553d018d486ca9ef11728933ab50319783bdf9cf77effc0810"
PROFILES = ("Vanilla", "TBC", "Wrath", "Cata", "Mists", "Forever")
EXPECTED = {"Vanilla": 862, "TBC": 1708, "Wrath": 2180, "Cata": 3013, "Mists": 3005, "Forever": 849}
CATALOG = ROOT / "Inventory/Restock/Auction/FluxAuctionRestockVendorCatalog.lua"
RETAIL_CATALOG = CATALOG.with_name("FluxAuctionRestockVendorCatalogRetail.lua")
LICENSE = ROOT / "licenses/LibItemDB-MIT.txt"
RETAIL_NOTICE = ROOT / "licenses/TrinityCore-VendorData.txt"


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def require(condition, message):
    if not condition:
        raise ValueError(message)


def read_pinned(path, expected):
    raw = path.read_bytes()
    require(sha(raw) == expected, f"Pinned source facts changed: {path}; review provenance before updating")
    return json.loads(raw)


def lua(value):
    return json.dumps(value, ensure_ascii=True)


def map_lines(name, rows, indent="    "):
    return [indent + name + " = {"] + [f"{indent}    [{item}]={price}," for item, price in sorted(rows.items())] + [indent + "}"]


def validate_retail(data, source_dir=None):
    m = data["manifest"]
    require(data["schemaVersion"] == 1 and data["license"] == "GPL-2.0-or-later", "Retail schema/license changed")
    require(m["trinity_commit"] == TC_PIN and m["client_build"] == "12.1.5.70783", "Retail source pin/build changed")
    require(m["source_release"] == "TDB1210.26091" and m["unit_rule"] == "ItemSparse.BuyPrice / max(ItemSparse.VendorStackCount, 1)", "Retail source/unit rule changed")
    prices, counts, stock_only, seen = {}, {}, {}, set()
    for row in data["rows"]:
        require(len(row) == 3, "Invalid Retail source row")
        item, raw_price, raw_count = row
        require(type(item) is int and item > 0 and item not in seen, "Invalid/duplicate Retail item ID")
        seen.add(item)
        require((raw_price is None and raw_count is None) or (type(raw_price) is int and raw_price >= 0 and type(raw_count) is int and raw_count >= 0), "Unknown Retail price/count must stay unknown")
        if raw_price is not None and raw_price > 0:
            prices[item] = raw_price
            count = max(raw_count, 1)
            if count != 1:
                counts[item] = count
        else:
            stock_only[item] = "true"
    require(len(seen) == m["distinct_stock_items"] == 3710 and len(prices) == m["priced_items"] == 3693, "Retail source cardinality changed")
    require(set(stock_only) == set(m["zero_or_negative_buy_price_ids"] + m["missing_sparse_ids"]), "Retail unknown prices must remain stock-only")
    require(len(m["input_files"]) == 104 and len(m["proof_files"]) == 5, "Retail SQL/proof source chain incomplete")
    require(m["gates"]["accepted_vendor_rows"] == 28939 and m["patches_inspected"] == 102, "Retail stock/patch gate proof changed")
    if source_dir:
        for entry in m["input_files"] + m["proof_files"] + m["generation_files"] + m["generated_files"]:
            raw = (source_dir / entry["file"]).read_bytes()
            require(len(raw) == entry["bytes"] and sha(raw) == entry["sha256"], "Retail original source differs: " + entry["file"])
        sparse = m["itemsparse_source"]
        require(sha((source_dir / sparse["file"]).read_bytes()) == sparse["sha256_compressed"], "Retail ItemSparse source differs")
        require(sha((source_dir / "TDB_full_1210.26091_2026_09_09.7z").read_bytes()) == m["archive_source"]["archive_sha256"], "Retail original TDB archive differs")
        evidence_raw = (source_dir / "retail-vendor-evidence.json").read_bytes()
        require(sha(evidence_raw) == data["sourceEvidenceSHA256"], "Retail per-item stock/price evidence changed")
        reconstructed = []
        for key, record in sorted(json.loads(evidence_raw).items(), key=lambda pair: int(pair[0])):
            item = int(key)
            require(bool(record["vendors"]), "Retail item has no gated vendor row")
            for vendor in record["vendors"]:
                require(vendor["item"] == item and vendor["maxcount"] == 0 and vendor["ExtendedCost"] == 0 and vendor["type"] == 1 and vendor["PlayerConditionID"] == 0, "Retail finite/currency/conditional row leaked")
            sparse = record["item_sparse"]
            raw_price = int(sparse["BuyPrice"]) if sparse else None
            raw_count = int(sparse["VendorStackCount"]) if sparse else None
            unit = raw_price / max(raw_count, 1) if raw_price and raw_price > 0 else None
            require(record["unit_price"] == unit, "Retail evidence unit normalization differs")
            reconstructed.append([item, raw_price, raw_count])
        require(reconstructed == data["rows"], "Retail compact facts differ from complete per-item evidence")
    return prices, counts, stock_only


def build(archive, retail_source_dir=None):
    units = read_pinned(ROOT / "tools/data/vendor_catalog_units.json", UNITS_SHA)
    retail = read_pinned(ROOT / "tools/data/vendor_catalog_retail.json", RETAIL_SHA)
    retail_prices, retail_counts, stock_only = validate_retail(retail, retail_source_dir)
    require(sha((ROOT / "licenses/TrinityCore-GPL-2.0.txt").read_bytes()) == TC_LICENSE_SHA, "Original TrinityCore GPL notice differs")
    require(units["schemaVersion"] == 1 and units["normalization"] == "BuyPrice / max(VendorStackCount, 1)", "Invalid physical-unit source schema")
    require(sha(archive.read_bytes()) == ARCHIVE_SHA, "Release ZIP differs from pinned SHA256; review source/version before updating")
    maps, buy_counts, metadata = {}, {}, {}
    with zipfile.ZipFile(archive) as source:
        license_text = source.read("ItemDB/LICENSE").decode("utf-8-sig")
        require("MIT License" in license_text and "Copyright (c) 2026 Pimptasty" in license_text, "Upstream license identity changed")
        for profile in PROFILES:
            path = f"ItemDB/Data/{profile}/_core/VendorPrices.lua"
            raw = source.read(path)
            text = raw.decode("utf-8-sig")
            require("(maxcount == 0 AND ExtendedCost == 0)" in text, "Missing unlimited gold-only source gate: " + path)
            pairs = re.findall(r"^\[(\d+)\]\s*=\s*(\d+),\s*$", text, re.M)
            rows = {int(item): int(price) for item, price in pairs}
            require(len(rows) == len(pairs) == EXPECTED[profile] and all(price > 0 for price in rows.values()), "Unexpected duplicate/count/price in " + path)
            match = re.search(r"-- client build ([\d.]+) - (\d+) of (\d+) shipped items", text)
            require(match and int(match[2]) == len(rows), "Invalid build/count header: " + path)
            unit = units["profiles"][profile]
            require(unit["clientBuild"] == match[1] and unit["sourceMapSHA256"] == sha(raw), "ItemSparse units do not match this source map/build")
            require(unit["sourceMapRows"] == unit["matchedRows"] == unit["rawBuyPriceMatches"] == len(rows), "Incomplete ItemSparse BuyPrice comparison")
            require(not unit["missingIDs"] and not unit["mismatches"] and not unit["duplicates"], "Missing/ambiguous ItemSparse unit evidence")
            require(unit["defaultVendorStackCount"] == 1 and unit["nonDefaultEnumerationComplete"] is True, "Cannot infer default unit count without exhaustive proof")
            ids_sha = sha(",".join(str(item) for item in sorted(rows)).encode("ascii"))
            require(ids_sha == unit["verifiedIDsSHA256"], "Verified unit-count item set differs")
            counts = {}
            for key, count in unit["nonDefaultVendorStackCounts"].items():
                item = int(key)
                require(item in rows and type(count) is int and count >= 0 and count != 1, "Invalid non-default vendor bundle fact")
                if count > 1:
                    counts[item] = count
            maps[profile], buy_counts[profile] = rows, counts
            metadata[profile] = {"sha": sha(raw), "build": match[1], "header": text.split("local lib", 1)[0].rstrip(), "unit": unit}
    lines = [
        "-- Generated by tools/build_vendor_catalog.py; do not hand-edit data rows.",
        "-- MIT source: " + RELEASE + " (12 November 2026), " + URL,
        "-- ZIP SHA256: " + ARCHIVE_SHA,
        "-- Copyright (c) 2026 Pimptasty; licenses/LibItemDB-MIT.txt.",
        "-- Physical-item BUY price = raw ItemSparse.BuyPrice / max(VendorStackCount,1).",
        "-- Unit facts: tools/data/vendor_catalog_units.json SHA256 " + UNITS_SHA,
        "-- Every MIT raw price/count was checked against its exact client build.",
        "-- Stock uses dated Wrath/Cata emulator unlimited gold-only npc_vendor gates,",
        "-- not native stock proof for every target. Retail is separately GPL licensed.",
        "-- Missing rows/prices stay UNKNOWN. No native action, timer, event or write.",
        "local _, ns = ...", "FluxAuctionRestock = FluxAuctionRestock or {}",
        "local client = ns.Flux and ns.Flux.Client or {}", "local profile",
        'if client.isForever or client.isCamelot then profile = "Forever"',
        'elseif client.isRetail then profile = "Retail"',
        'elseif client.isMists then profile = "Mists"',
        'elseif client.isCata then profile = "Cata"',
        'elseif client.isWrath then profile = "Wrath"',
        'elseif client.isTBC or client.isAnniversary then profile = "TBC"',
        'elseif client.isEra or client.isClassicEra then profile = "Vanilla" end',
        "local prices, buyCounts, stockOnly, metadata", "",
    ]
    for index, profile in enumerate(PROFILES):
        info, rows = metadata[profile], maps[profile]
        unit = info["unit"]
        lines += [f'if profile == "{profile}" then' if index == 0 else f'elseif profile == "{profile}" then', "    -- Original generated input header:"]
        lines += ["    " + line for line in info["header"].splitlines()]
        lines += [f'    -- Input SHA256: {info["sha"]}', f'    -- ItemSparse source: {unit["url"]}',
                  f'    -- CSV SHA256: {unit["itemSparseSHA256"]}; all {len(rows)} raw prices/counts verified.',
                  "    metadata = {", f'        clientBuild = {lua(info["build"])}, sourceSHA256 = {lua(info["sha"])},',
                  f'        unitSourceSHA256 = {lua(unit["itemSparseSHA256"])}, source = {lua(RELEASE)},',
                  f'        releaseURL = {lua(URL)}, archiveSHA256 = {lua(ARCHIVE_SHA)},',
                  f'        stockCount = {len(rows)}, pricedCount = {len(rows)}, maxItemID = {max(rows)},', "    }"]
        lines += map_lines("prices", rows) + map_lines("buyCounts", buy_counts[profile])
    lines += ['elseif profile == "Retail" then', "    local retail = FluxAuctionRestock._VendorCatalogRetail", "    if retail then",
              "        prices, buyCounts, stockOnly, metadata = retail.prices, retail.buyCounts, retail.stockOnly, retail.metadata", "    end", "end",
              "FluxAuctionRestock._VendorCatalogRetail = nil", "", "local catalog = {",
              "    profile = profile, source = metadata and metadata.source,",
              "    releaseURL = metadata and metadata.releaseURL, archiveSHA256 = metadata and metadata.archiveSHA256,",
              "    count = metadata and metadata.stockCount or 0, pricedCount = metadata and metadata.pricedCount or 0, metadata = metadata,", "}",
              "local function ID(itemID)", "    if issecretvalue and issecretvalue(itemID) then return end", "    local id = tonumber(itemID)",
              "    if id and id > 0 and id % 1 == 0 then return id end", "end",
              "function catalog.Has(itemID)", "    local id = ID(itemID)", "    return id ~= nil and ((prices and prices[id] ~= nil) or (stockOnly and stockOnly[id] == true)) or false", "end",
              "function catalog.GetTerms(itemID)", "    local id = ID(itemID)", "    local raw = id and prices and prices[id]", "    if raw then return raw, buyCounts[id] or 1 end", "end",
              "function catalog.Get(itemID)", "    local raw, count = catalog.GetTerms(itemID)", "    return raw and raw / count or nil, profile, catalog.source", "end",
              "FluxAuctionRestock.VendorCatalog = catalog", ""]
    notice = license_text.rstrip() + "\n\nBundled data: " + RELEASE + " generated vendor BUY-price maps only.\n"
    notice += "Release: " + URL + "\nDownload: " + DOWNLOAD + "\nZIP SHA256: " + ARCHIVE_SHA + "\n"
    notice += ("Input headers and map/CSV SHA256 identities are retained in the catalog.\n"
               "Stock eligibility uses Wrath/Cata emulator npc_vendor maxcount == 0 and\n"
               "ExtendedCost == 0; each profile's raw ItemSparse.BuyPrice is divided by its\n"
               "verified max(VendorStackCount, 1) for a physical-item price. All 11617 raw\n"
               "prices matched the exact-build CSV; default counts are exhaustive.\n"
               "Unit inputs: tools/data/vendor_catalog_units.json; SHA256: " + UNITS_SHA + "\n"
               "Formula facts verified in TrinityCore ItemTemplate.h/GetBuyCount and Player.cpp,\n"
               "pin " + TC_PIN + "; no C++ implementation copied.\n"
               "Dated generated evidence is not native stock/access or character-discount\n"
               "proof. Missing rows stay unknown. No ItemDB runtime is included.\n"
               "Retail is separate GPL-2.0-or-later data; see TrinityCore-VendorData.txt.\n")
    m = retail["manifest"]
    retail_lines = [
        "-- Generated by tools/build_vendor_catalog.py; do not hand-edit data rows.",
        "-- SPDX-License-Identifier: GPL-2.0-or-later",
        "-- TrinityCore Project vendor data; licenses/TrinityCore-GPL-2.0.txt and",
        "-- licenses/TrinityCore-VendorData.txt. No engine implementation copied.",
        "-- Pin: " + TC_PIN + "; TDB1210.26091 + 102 inspected SQL updates.",
        "-- Compact source facts SHA256: " + RETAIL_SHA,
        "-- Unlimited gold item rows; no ExtendedCost, PlayerConditionID or server",
        "-- vendor condition. NPC access/phasing/faction/reputation are unverified.",
        "-- Price = raw ItemSparse.BuyPrice / max(VendorStackCount,1), client 12.1.5.70783.",
        "-- 3710 stock IDs; 3693 prices; 17 unknown prices stay stock-only.",
        "-- Load BEFORE VendorCatalog.lua, then Data.lua.",
        "local _, ns = ...", "local client = ns.Flux and ns.Flux.Client or {}",
        "if not client.isRetail or client.isForever or client.isCamelot then return end",
        "FluxAuctionRestock = FluxAuctionRestock or {}", "local prices, buyCounts, stockOnly",
    ]
    retail_lines += map_lines("prices", retail_prices, "") + map_lines("buyCounts", retail_counts, "") + map_lines("stockOnly", stock_only, "")
    retail_lines += ["FluxAuctionRestock._VendorCatalogRetail = {", "    prices = prices, buyCounts = buyCounts, stockOnly = stockOnly,", "    metadata = {",
                     '        clientBuild = "12.1.5.70783", source = "TrinityCore-TDB1210.26091",',
                     f'        sourceSHA256 = "{RETAIL_SHA}", unitSourceSHA256 = "{m["itemsparse_source"]["sha256_raw"]}",',
                     f'        releaseURL = "{m["archive_source"]["source"]}", archiveSHA256 = "{m["archive_source"]["archive_sha256"]}",',
                     f'        sourceCommit = "{TC_PIN}", stockCount = 3710, pricedCount = 3693, maxItemID = {max(set(retail_prices) | set(stock_only))},', "    },", "}", ""]
    retail_notice = (
        "TrinityCore Project - generated Retail vendor data\nSPDX-License-Identifier: GPL-2.0-or-later\n"
        "Original GPL notice: TrinityCore-GPL-2.0.txt\nAttribution/AUTHORS: " + retail["attribution"] + "\n"
        "Source: https://github.com/TrinityCore/TrinityCore/tree/" + TC_PIN + "\n"
        "Base archive: " + retail["archiveDownloadURL"] + "\nBase archive SHA256: " + m["archive_source"]["archive_sha256"] + "\n"
        "Compact facts: tools/data/vendor_catalog_retail.json\nCompact facts SHA256: " + RETAIL_SHA + "\n"
        "Original per-item evidence SHA256: " + retail["sourceEvidenceSHA256"] + "\n"
        "ItemSparse CSV: " + m["itemsparse_source"]["url"] + "\nRaw CSV SHA256: " + m["itemsparse_source"]["sha256_raw"] + "\n\n"
        "Transformation: only npc_vendor and conditions were extracted from the base\n"
        "archive. All 102 current pinned world updates were inspected; 26 relevant SQL\n"
        "statements were replayed for these two tables. Accept unlimited (maxcount=0),\n"
        "gold-only (ExtendedCost=0), positive item rows (type=1), with no row\n"
        "PlayerConditionID or server vendor condition. Distinct stock IDs: 3710.\n"
        "Client-build 12.1.5.70783 ItemSparse supplies raw BuyPrice and VendorStackCount.\n"
        "Physical-item price = BuyPrice/max(VendorStackCount,1). 3693 positive prices;\n"
        "15 zero and 2 missing ItemSparse rows stay stock-only with unknown prices.\n"
        "No engine implementation copied, full world database materialized, native UI\n"
        "automation or addon dependency added. Input SQL/patch/proof hashes, build,\n"
        "gates and generation identities are preserved in the compact JSON manifest.\n"
        "Source-derived reference data does not certify character faction/class/\n"
        "reputation, NPC spawn/phasing/access, native availability or discounts.\n"
        "Typed in-game merchant observations override it.\n\n"
        "Rebuild: python tools/build_vendor_catalog.py <pinned ItemDB ZIP>\n"
        "Append --retail-source-dir <directory matching compact manifest> to verify\n"
        "original Retail SQL/proof/CSV/evidence. Append --check to compare, not write.\n"
    )
    return {CATALOG: "\n".join(lines), LICENSE: notice, RETAIL_CATALOG: "\n".join(retail_lines), RETAIL_NOTICE: retail_notice}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", type=pathlib.Path, help="Pinned ItemDB-ItemDB-v1.9.0.zip")
    parser.add_argument("--retail-source-dir", type=pathlib.Path, help="Validate original pinned Retail SQL/proof/CSV/evidence")
    parser.add_argument("--check", action="store_true", help="Compare generated files without writing")
    args = parser.parse_args()
    for path, content in build(args.archive, args.retail_source_dir).items():
        if args.check:
            require(path.exists() and path.read_text(encoding="utf-8") == content, "Generated file differs: " + str(path))
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8", newline="\n")
    print(f"Vendor catalog {'verified' if args.check else 'generated'}: 15327 stock IDs, 15310 physical-unit prices, seven selected-client source profiles")


if __name__ == "__main__":
    main()
