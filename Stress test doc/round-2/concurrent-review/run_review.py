"""Bounded read-only review of independently changing PvP source identities."""
from pathlib import Path
from datetime import datetime, timezone
import difflib
import hashlib
import json
import subprocess
import zipfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
ROUND = HERE.parent
paths = ["UnitFrames/FluxUnitFrames_Shared.lua", "UnitFrames/FluxUnitFrames_Party.lua",
         "tests/raid_party_frames.lua", "tests/unit_indicator_layout.lua"]
baseline = json.loads((ROUND / "baseline.json").read_text(encoding="utf-8"))
with zipfile.ZipFile(Path(baseline["externalSnapshot"]) / "source.zip") as archive:
    initial = {path: archive.read(path) for path in paths}
before_data = {path: (ROOT / path).read_bytes() for path in paths}
digest = lambda data: hashlib.sha256(data).hexdigest()
before = {path: digest(data) for path, data in before_data.items()}
(HERE / "source-before.json").write_text(json.dumps({"capturedUTC": datetime.now(timezone.utc).isoformat(), "sources": before}, indent=2) + "\n", encoding="utf-8")
changes = []
for path in paths:
    old = initial[path].decode("utf-8-sig").replace("\r\n", "\n")
    current = before_data[path].decode("utf-8-sig").replace("\r\n", "\n")
    delta = "".join(difflib.unified_diff(old.splitlines(True), current.splitlines(True), fromfile="initial-round2/" + path, tofile="review-snapshot/" + path))
    patch = path.replace("/", "_") + ".patch"
    (HERE / patch).write_text(delta, encoding="utf-8")
    changes.append({"path": path, "initialRound2SHA256": digest(initial[path]), "reviewSnapshotSHA256": before[path],
                    "changedFromInitialRound2": initial[path] != before_data[path], "patch": patch,
                    "attribution": "Independent changes, preserved; this audit issued no source/test writes"})
def section(text, first, last):
    start = text.index(first)
    return text[start:text.index(last, start + len(first))]
old_shared = initial[paths[0]].decode("utf-8-sig").replace("\r\n", "\n")
new_shared = before_data[paths[0]].decode("utf-8-sig").replace("\r\n", "\n")
dom04 = []
for name, first, last in [("portrait", "function UF.UpdatePortraitCombatTint(self)", "function UF.UpdateBorderColors(self)"),
                          ("threatRaise", "local function ThreatBarRaiseGlowAboveBorder(shell)", "local function RetireLegacyThreatOverlay(overlay)")]:
    old, current = section(old_shared, first, last), section(new_shared, first, last)
    dom04.append({"body": name, "initialNormalizedSHA256": digest(old.encode()), "currentNormalizedSHA256": digest(current.encode()), "unchanged": old == current})
reference = ROOT.parent / "__AddonsForRef/wow-ui-source-forever/Interface/AddOns/Blizzard_UnitFrame"
contracts = []
for name in ["Shared/UnitFrameUtil.lua", "Camelot/UnitFramePvPIndicatorStyle.lua", "Mainline/UnitFramePvPIndicatorStyle.lua"]:
    data = (reference / name).read_bytes().replace(b"\r\n", b"\n")
    contracts.append({"path": "Interface/AddOns/Blizzard_UnitFrame/" + name,
                      "gitBlob": hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest(),
                      "localReferenceCommit": "9dc84f0d3bbae1768ac3405b3716000bd93eda06",
                      "note": "Forever checkout contains both Camelot/Mainline style paths; actual current Live equivalence requires root primary fetch verification."})
commands = [["lua", str(HERE / "pvp_native_helper.lua.txt")],
            ["lua", str(HERE / "paging_scope_control.lua.txt")],
            ["lua", "Stress test doc/round-2/remaining-domains/frame_level_reads.lua.txt"],
            ["lua", "tests/unit_indicator_layout.lua"], ["lua", "tests/raid_party_frames.lua"],
            ["lua", "tests/restricted_driver_ownership.lua"], ["lua", "tests/unit_identity_feedback.lua"]]
dependency_paths = [ROOT / p for p in ["Bars/State.lua", "Bars/SlotMath.lua", "Bars/Hosts.lua", "Bars/Watch.lua", "Core/Engine/Restricted.lua",
                                     "Stress test doc/round-2/modifier-storm/consumer_budgets.lua.txt",
                                     "Stress test doc/round-2/remaining-domains/frame_level_reads.lua.txt"]]
dependency_paths += list(HERE.glob("*.lua.txt")) + [Path(__file__)]
dependency_paths += [reference / name for name in ["Shared/UnitFrameUtil.lua", "Camelot/UnitFramePvPIndicatorStyle.lua", "Mainline/UnitFramePvPIndicatorStyle.lua"]]
dependency_before = {str(p): digest(p.read_bytes()) for p in dependency_paths}
tests = []
for command in commands:
    p = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, timeout=90)
    tests.append({"command": command, "exit": p.returncode, "stdout": p.stdout, "stderr": p.stderr})
after = {path: digest((ROOT / path).read_bytes()) for path in paths}
dependency_after = {str(p): digest(p.read_bytes()) for p in dependency_paths}
out = {"capturedUTC": datetime.now(timezone.utc).isoformat(), "scope": "Four independently changed files, current PvP formatter/native helper model, unchanged DOM04 bodies. No runtime/test/settings/game writes; not a full current-addon pass.",
       "changes": changes, "DOM04Bodies": dom04, "contracts": contracts, "tests": tests,
       "sourcesBefore": before, "sourcesAfter": after, "driftDuringProbe": [p for p in before if before[p] != after[p]],
       "dependencySourcesBefore": dependency_before, "dependencySourcesAfter": dependency_after,
       "dependencyDriftDuringProbe": [p for p in dependency_before if dependency_before[p] != dependency_after[p]],
       "allFocusedTestsPassed": all(t["exit"] == 0 for t in tests), "nativeErrorsObserved": 0,
       "newFaultEstablishedInPvpDelta": False,
       "limits": "CreateSecureDelegate and secret wrapping are modeled, not native security permissions; opaque visibility isn't read. Pixel/secure/native timing and additional source updates remain pending. Earlier whole-addon byte preservation cannot be claimed."}
(HERE / "results.json").write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
print(json.dumps({k: out[k] for k in ("allFocusedTestsPassed", "driftDuringProbe", "dependencyDriftDuringProbe", "newFaultEstablishedInPvpDelta")}))
print(json.dumps(contracts))
for test in tests: print(test["stdout"].strip() or test["stderr"].strip())
raise SystemExit(0 if out["allFocusedTestsPassed"] and not out["driftDuringProbe"] and not out["dependencyDriftDuringProbe"] else 1)
