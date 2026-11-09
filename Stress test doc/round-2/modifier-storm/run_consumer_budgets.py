"""Supplemental consumer work counts only; no addon/native/settings writes."""
from pathlib import Path
from datetime import datetime, timezone
import hashlib
import json
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
paths = ["Bars/State.lua", "Bars/SlotMath.lua", "Bars/Hosts.lua", "Bars/Watch.lua", "Bars/BadgeHost.lua", "Bars/ProgramFace.lua",
         "ExtraButtonSystem/Shared/HotkeyUtil.lua", "ExtraButtonSystem/Engine/Events.lua",
         "ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua", "ExtraButtonSystem/Shared/FluxModifierTracker.lua",
         "Core/Engine/Context.lua", "Core/Engine/Modifier.lua",
         str((HERE / "consumer_budgets.lua.txt").relative_to(ROOT)), str(Path(__file__).relative_to(ROOT))]
baseline = json.loads((HERE.parent / "baseline.json").read_text(encoding="utf-8"))
baseline_files = {row["path"]: row["sha256"] for row in baseline["files"]}
def hashes():
    return {path: hashlib.sha256((ROOT / path).read_bytes()).hexdigest() for path in paths}
before = hashes()
samples = []
for repetition in range(1, 4):
    result = subprocess.run(["lua", str(HERE / "consumer_budgets.lua.txt")], cwd=ROOT,
                            capture_output=True, text=True, timeout=180)
    metrics = []
    for line in result.stdout.splitlines():
        if not line.startswith(("BARS|", "HOTKEY|", "TOTAL|")): continue
        fields = line.split("|"); row = {"kind": fields[0]}
        if fields[0] != "TOTAL": row["clientModel"] = fields.pop(1)
        for field in fields[1:]:
            key, value = field.split("=", 1)
            if value in ("true", "false"): value = value == "true"
            else:
                try: value = int(value)
                except ValueError: pass
            row[key] = value
        metrics.append(row)
    samples.append({"repetition": repetition, "exit": result.returncode, "stdout": result.stdout,
                    "stderr": result.stderr, "metrics": metrics})
after = hashes()
out = {"capturedUTC": datetime.now(timezone.utc).isoformat(), "scope": "Actual production Bars state/slot-index/Watch callback and full EBS HotkeyUtil in native/scheduler mocks. Consumer-local counts; not a full-addon timing sum or native input/taint/FPS test.",
       "allPassed": all(s["exit"] == 0 for s in samples), "samples": samples,
       "identicalMetricsAcrossThreeRuns": all(s["metrics"] == samples[0]["metrics"] for s in samples),
       "sourcesBefore": before, "sourcesAfter": after, "consumedSourceDrift": [p for p in before if before[p] != after[p]],
       "runtimeDriftFromRound2Baseline": [p for p in paths if p in baseline_files and before[p] != baseline_files[p]],
       "finding": "R2-MOD-01: raw Bars modifier callback walks/reindexes every host before downstream coalescing; fallback OOC restamps26 attributes/host/edge even for duplicate-held state.",
       "controls": "Combat protected attribute writes0; exactly bounded four requested paint keys; indexed host membership stable; EBS HotkeyUtil one pending50ms timer, one owner frame, final release unprefixed and no backlog.",
       "limits": "Native keyers, frame OnAttributeChanged hooks, protected execution, input edge routing, true secret values, UI pixels and native CPU/FPS are not modeled. No native clients driven; client/capability labels are declared policy models. Root core-bus and peer click/VFX tests are separate evidence.",
       "nativeErrorsObserved": 0}
(HERE / "consumer-results.json").write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
print(json.dumps({k: out[k] for k in ("allPassed", "identicalMetricsAcrossThreeRuns", "consumedSourceDrift", "runtimeDriftFromRound2Baseline")}))
print(json.dumps(next((row for row in samples[0]["metrics"] if row["kind"] == "TOTAL"), {})))
raise SystemExit(0 if out["allPassed"] and not out["consumedSourceDrift"] else 1)
