"""Read-only round-2 domain review, production-owner probes and coverage ledger."""
from pathlib import Path
from datetime import datetime, timezone
import csv
import hashlib
import json
import re
import runpy
import subprocess
import sys

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
ROUND = HERE.parent
DOMAINS = ["UnitFrames", "RaidFrame", "NamePlates", "Inventory", "Mail", "Salvage", "Minimap", "MicroMenu",
           "Battlezonemap", "CharacterInfo", "Other", "StatusBars", "BaganatorCompat"]
MANUAL = {
    "UnitFrames": {"FluxUnitFrames_Shared.lua": "public geometry/level ledger, prediction helpers, portrait combat chrome, private threat raising",
                   "FluxUnitFrames_Pet.lua": "public parent-level/dimension writers", "FluxUnitFrames_TargetOfTarget.lua": "public parent-level/dimension writers"},
    "RaidFrame": {"FluxRaidUnit.lua": "paint-arm lifecycle and visible range poll cancellation", "FluxRaidHoTs.lua": "visible work set, aura access gate, ticker stop"},
    "NamePlates": {"Core.lua": "module/Forever/Live driver ownership, active-unit fanout, prior unchanged-write guards"},
    "Inventory": {"LegacyBridge.lua": "active listener routing", "FluxInv/FluxInv_Events.lua": "legacy queue triage; not TOC-reachable",
                  "Builtin/Mail.lua": "scan generation, bounded incomplete retry, publication gate", "Syndicator/Adapter.lua": "mail debounce and initial provider handoff; excluded guild/void callbacks not reviewed",
                  "Restock/Bank/FluxBankRestockMoveExec.lua": "active-frame visibility, timeout/reset/phase ownership (not guild bank)",
                  "Restock/Junk/FluxVendorJunkPanel.lua": "metadata query, active list, tab entry and retries",
                  "Restock/Vendor/FluxVendorRestockPanel.lua": "metadata query, tab entry, hidden/storm/debounce guards"},
    "Mail": {"Select.lua": "worker/action identity, watchdog cancellation, module-disable stop", "OpenAll.lua": "eligibility and native progress delegation",
             "QuickAttach.lua": "mail/combat/modifier/cursor gates", "TradeBlock.lua": "mailbox lifetime and prior CVar restore",
             "Contacts.lua": "recipient normalization, bounded recent list", "CategoryAttach.lua": "install retry and settings visibility"},
    "Salvage": {"FluxSalvage_Overlay.lua": "entire production module in strict existing fixture; visible combat update/modifier paths"},
    "Minimap": {"FluxMinimap.lua": "current clock/calendar handlers and show/hide ticker lifecycle", "FluxMinimapButtons.lua": "saved action capture and EBS delegation"},
    "MicroMenu": {"FluxMinimapToMicro.lua": "complete proxy create/rebuild/hover owner functions; finite login watcher",
                  "FluxMicroMenu.lua": "complete native proxy factory called by the conversion owner; both shell branches"},
    "Battlezonemap": {"FluxDetails.lua": "bounded containment watchdog and complete size-hook debounce",
                      "FluxBattlefieldMap.lua": "initialization watcher reuse, combat stop, bounded checks",
                      "FluxMeterLayout.lua": "splitter OnUpdate arm/disarm", "FluxThreat.lua": "visible/combat/event-led poll gates",
                      "FluxMeterSkin.lua": "public-number/theme gates; prior getter guard controls retained"},
    "CharacterInfo": {"PaperDollEquipFlyout.lua": "hover ticker/panel lifetime and flyout entry/leave routing", "Shared.lua": "coalesced player-stat refresh",
                      "PaperDollVisibility.lua": "native visibility sync hook/install ownership"},
    "Other": {"FluxEquipSlotFlyout.lua": "actual show/hide timer owner and notify entrypoints; Show preconditions source review",
              "FluxLoot.lua": "visible row pool, expiration driver, bounded session claims", "FluxLootRollPosition.lua": "combat defer and finite startup watcher",
              "FluxChatFrame.lua": "chat drift ticker and edit-mode hold", "FluxChatColumnMicros.lua": "prior hidden-watch fix retained"},
    "StatusBars": {"FluxStatusBar.lua": "actual integrated layout notification coalescer", "FluxInfoFrame.lua": "actual integrated cooldown coalescer, stats/tooltip ticker start/stop",
                   "FluxItemCurrencyTracking.lua": "pending icon refresh flag and generation-gated retries", "FluxPVPObjectiveMover.lua": "layout hooks, combat/layout entry and widget debounce"},
    "BaganatorCompat": {"Loader.lua": "late dependencies and initialization latch", "FluxBaganator_Junk.lua": "NewTimer cancellation control",
                       "FluxBaganator_Protection.lua": "NewTimer cancellation control and visible protection refresh"},
}
FINDINGS = {"R2-DOM-01": ["MicroMenu"], "R2-DOM-02": ["MicroMenu"], "R2-DOM-03": ["Salvage"],
            "R2-DOM-04": ["UnitFrames"], "R2-DOM-05": ["Inventory"], "R2-DOM-06": ["StatusBars", "Battlezonemap", "Other", "CharacterInfo"]}
PROBES = {"micro_proxy.lua.txt": 32, "salvage_combat.lua.txt": 45, "frame_level_reads.lua.txt": 11,
          "vendor_metadata.lua.txt": 30, "layout_after_token.lua.txt": 25}
PATTERNS = {"updateDriver": r'(?:SetScript|HookScript)\("OnUpdate"', "timers": r'C_Timer\.(?:After|NewTimer|NewTicker)',
            "nativeHooks": r'hooksecurefunc|HookScript', "nativeDimensions": r':Get(?:Width|Height|Point|FrameLevel|Alpha)\(',
            "combatGuards": r'InCombatLockdown|PLAYER_REGEN', "protectedWrites": r':(?:SetAttribute|SetPoint|ClearAllPoints|SetParent)\('}
baseline = json.loads((ROUND / "baseline.json").read_text(encoding="utf-8"))
baseline_rows = {row["path"]: row for row in baseline["files"]}
paths = sorted(p for domain in DOMAINS for p in (ROOT / domain).rglob("*.lua"))
dependencies = [ROOT / "tests/salvage_overlay.lua", ROOT / "_FluxUI.toc", ROOT / "Core/FluxAPI/Timers.lua"]
consumed = paths + dependencies + list(HERE.glob("*.lua.txt")) + [Path(__file__)]
def hashes():
    return {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in consumed}
before = hashes()
graph = runpy.run_path(str(ROOT / "docs/tools/source_inventory.py"), run_name="round2_inventory")["load_graph"]()
coverage = []
for p in paths:
    rel = p.relative_to(ROOT).as_posix(); domain, local = rel.split("/", 1)
    content = p.read_text(encoding="utf-8-sig", errors="replace")
    coverage.append({"path": rel, "domain": domain, "TOCReachable": rel in graph["reachable"],
                     "TOCClients": graph["reachable"].get(rel, {}).get("clients", []),
                     "manualBoundedReview": MANUAL.get(domain, {}).get(local),
                     "lexicalHintsNotRuntimeCounts": {key: len(re.findall(pattern, content)) for key, pattern in PATTERNS.items()},
                     "sha256": before[rel], "matchesRound2Baseline": before[rel] == baseline_rows.get(rel, {}).get("sha256")})
samples = []
for repetition in range(1, 6):
    tests = []
    for name, checks in PROBES.items():
        p = subprocess.run(["lua", str(HERE / name)], cwd=ROOT, capture_output=True, text=True, timeout=90)
        tests.append({"probe": name, "checksExpected": checks, "exit": p.returncode, "stdout": p.stdout, "stderr": p.stderr})
    samples.append({"repetition": repetition, "tests": tests})
after = hashes()
contracts = []
reference = ROOT.parent / "__AddonsForRef/wow-ui-source-forever/Interface/AddOns/Blizzard_APIDocumentationGenerated"
for name, blob in [("SimpleFrameAPIDocumentation.lua", "07debf919e8b4d43087306d2eccfb8e18e8f2c82"),
                   ("SimpleScriptRegionResizingAPIDocumentation.lua", "6425c8deefe565688f200fbff9d46c364a8f539b"),
                   ("UITimerDocumentation.lua", "8aff5217b9b1e4c97cfad2489e669ce561f05123")]:
    data = (reference / name).read_bytes().replace(b"\r\n", b"\n")
    actual = hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()
    assert actual == blob, name
    contracts.append({"path": name, "ForeverGitBlob": actual, "commit": "9dc84f0d3bbae1768ac3405b3716000bd93eda06"})
report = {"capturedUTC": datetime.now(timezone.utc).isoformat(), "head": baseline["head"],
          "scope": "Read-only source triage and bounded manual review; exact production owner functions/complete salvage module in desktop mocks. No native input, game/settings/profiler operations. Native secret VM/protected execution provenance/pixels/FPS unverified.",
          "sourceFilesTriaged": len(coverage), "reachableTriaged": sum(row["TOCReachable"] for row in coverage),
          "manualBoundedFileReviews": sum(bool(row["manualBoundedReview"]) for row in coverage),
          "assertionsPerRepetition": sum(PROBES.values()), "assertionsAcrossFiveRepetitions": sum(PROBES.values()) * 5,
          "nativeErrorsObserved": 0, "allProbesPassed": all(t["exit"] == 0 for sample in samples for t in sample["tests"]),
          "sourcesBefore": before, "sourcesAfter": after, "consumedSourceDrift": [p for p in before if before[p] != after[p]],
          "preExistingDomainSourceDriftFromRound2Baseline": [row["path"] for row in coverage if not row["matchesRound2Baseline"]],
          "samples": samples, "contracts": contracts, "loadGraphMissing": graph["missing"],
          "nativeAndBranchLimits": "Micro proxy and most timer owners have no client-specific branch: repeated labels are policy labels, not four engines. FrameLevel opaque tests target the permitted modern/Forever aspect contract, not a claim of opaque Classic levels. Salvage uses existing five-client strict templates/native mutation mocks; actual combat visibility/denial remains native pending.",
          "excluded": "Guild-bank and void-storage callbacks; no edits or new tests in runtime/tests/TOC; historical dormant sources are not active findings."}
(HERE / "results.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
(HERE / "coverage.json").write_text(json.dumps(coverage, indent=2) + "\n", encoding="utf-8")
with (HERE / "module-coverage.csv").open("w", newline="", encoding="utf-8") as output:
    writer = csv.writer(output)
    writer.writerow(["Domain", "LuaFilesLexicallyTriaged", "TOCReachable", "BoundedManualFileReviews", "ActualCheckedPaths", "NewFindingGroups", "Limits"])
    for domain in DOMAINS:
        rows = [row for row in coverage if row["domain"] == domain]
        writer.writerow([domain, len(rows), sum(row["TOCReachable"] for row in rows), sum(bool(row["manualBoundedReview"]) for row in rows),
                         "; ".join(row["path"] + ": " + row["manualBoundedReview"] for row in rows if row["manualBoundedReview"]),
                         ",".join(key for key, domains in FINDINGS.items() if domain in domains),
                         "Lexical triage is not execution coverage. Existing full-suite baseline is separate. Native combat/secret/pixel/performance checks pending; no safety certification."])
print(json.dumps({k: report[k] for k in ("allProbesPassed", "sourceFilesTriaged", "reachableTriaged", "manualBoundedFileReviews", "assertionsAcrossFiveRepetitions", "consumedSourceDrift", "preExistingDomainSourceDriftFromRound2Baseline", "loadGraphMissing")}))
raise SystemExit(0 if report["allProbesPassed"] and not report["consumedSourceDrift"] else 1)
