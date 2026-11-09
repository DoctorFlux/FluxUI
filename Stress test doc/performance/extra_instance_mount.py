"""Separate, read-only actual-instance geography extension to the main audit."""
from pathlib import Path
from datetime import datetime, timezone
import hashlib
import json
import subprocess
import time

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
SCRIPT = HERE / "extra_instance_mount.lua.txt"
SOURCES = ("Inventory/MountFlyable.lua", "Core/Client.lua", "Core/Capabilities.lua")
def hashes():
    return {rel: hashlib.sha256((ROOT / rel).read_bytes()).hexdigest() for rel in SOURCES}
before = hashes()
runs = []
for repetition in range(1, 6):
    start = time.perf_counter()
    result = subprocess.run(["lua", str(SCRIPT)], cwd=ROOT, capture_output=True, text=True, timeout=60)
    metrics = []
    for line in result.stdout.splitlines():
        if not line.startswith("RESULT|"):
            continue
        _, case, *fields = line.split("|")
        row = {"case": case}
        for field in fields:
            name, value = field.split("=", 1)
            try:
                value = int(value)
            except ValueError:
                if value in {"true", "false"}:
                    value = value == "true"
            row[name] = value
        metrics.append(row)
    runs.append({"repetition": repetition, "exit_code": result.returncode,
                 "desktop_wall_seconds": round(time.perf_counter() - start, 6),
                 "metrics": metrics, "stdout": result.stdout, "stderr": result.stderr})
after = hashes()
report = {"captured_at_utc": datetime.now(timezone.utc).isoformat(),
          "scope": "Complete production Inventory/MountFlyable.lua executed with synthetic native API values; client flags match current Core/Client.lua. The helper owns geography/preference, not mount execution, secure input, combat legality, taint or FPS.",
          "separate_from_main_20_process_results": True,
          "command": "python 'Stress test doc/performance/extra_instance_mount.py'",
          "script_sha256": hashlib.sha256(SCRIPT.read_bytes()).hexdigest(),
          "source_raw_sha256_before": before, "source_raw_sha256_after": after,
          "source_drift": [rel for rel in before if before[rel] != after[rel]],
          "all_processes_passed": all(run["exit_code"] == 0 for run in runs),
          "metrics_identical_across_five_repetitions": all(run["metrics"] == runs[0]["metrics"] for run in runs),
          "tests": runs}
(HERE / "extra_instance_results.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
print(json.dumps({key: report[key] for key in ("all_processes_passed", "metrics_identical_across_five_repetitions", "source_drift")}))
print(json.dumps(runs[0]["metrics"][-1]))
raise SystemExit(0 if report["all_processes_passed"] else 1)
