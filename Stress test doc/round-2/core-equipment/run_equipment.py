"""Read-only production Equipment/orchestrator replay; evidence stays here."""
import hashlib
import json
import pathlib
import re
import subprocess
from datetime import datetime, timezone

OUT = pathlib.Path(__file__).resolve().parent
ROOT = OUT.parents[2]
HARNESS = OUT / "equipment_pipeline.lua.txt"
PATHS = [ROOT / p for p in (
    "Respec/FluxRespec_Compat.lua", "Respec/FluxRespec_Includes.lua", "Respec/FluxRespec_Inv.lua",
    "Respec/FluxRespec_Equipment.lua", "Respec/FluxRespec_EquipmentSets.lua", "Respec/FluxRespec_Apply.lua",
    "Respec/FluxRespec_Core.lua", "Respec/FluxRespec_UI.lua", "Respec/FluxRespec_EquipmentPresets.lua", "_FluxUI.toc"
)] + [HARNESS, pathlib.Path(__file__).resolve()]


def manifest():
    return {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in PATHS}


before = manifest()
records = []
for repeat in range(1, 4):
    r = subprocess.run(["lua", str(HARNESS.relative_to(ROOT))], cwd=ROOT, capture_output=True, text=True, timeout=30)
    summary = next((line for line in r.stdout.splitlines() if line.startswith("SUMMARY ")), "")
    counts = {k: int(v) for k, v in re.findall(r"(\w+)=(\d+)", summary)}
    records.append({"repeat": repeat, "exit": r.returncode, "counts": counts, "stdout": r.stdout, "stderr": r.stderr})
    print(f"repeat {repeat}: {'PASS' if not r.returncode else 'FAIL'} {counts}")
after = manifest()
drift = [p for p in before if before[p] != after[p]]
report = {"capturedUTC": datetime.now(timezone.utc).isoformat(),
          "scope": "Complete production Lua with public inventory/native-operation mocks; no actual gear/game/input/settings changes",
          "sourceNormalization": "raw bytes", "before": before, "after": after, "drift": drift,
          "uniqueHarnesses": 1, "repeats": 3, "executions": 3,
          "checksPerRun": records[0]["counts"].get("checks"), "totalChecks": sum(r["counts"].get("checks", 0) for r in records),
          "stdoutDeterministic": len({r["stdout"] for r in records}) == 1,
          "pass": sum(r["exit"] == 0 for r in records), "fail": sum(r["exit"] != 0 for r in records), "records": records}
(OUT / "results.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
assert report["pass"] == 3 and not drift and report["stdoutDeterministic"], "audit failed or source drift"
