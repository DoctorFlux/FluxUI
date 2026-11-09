"""Capture bounded extended Mail/Salvage simulations. Writes this folder only."""
import hashlib
import json
import pathlib
import subprocess
import time
from datetime import datetime, timezone

here = pathlib.Path(__file__).resolve().parent
root = here.parent.parent
sources = ["Mail/Settings.lua", "Mail/Select.lua", "Mail/OpenAll.lua",
           "Salvage/FluxSalvage_Overlay.lua", "tests/mail_job_lifecycle.lua",
           "tests/salvage_overlay.lua", "Stress test doc/security/surface_lifecycle_stress.lua.txt"]
def hashes():
    return {p: hashlib.sha256((root / p).read_bytes()).hexdigest() for p in sources}
before = hashes()
samples = []
for index in range(3):
    began = time.perf_counter()
    result = subprocess.run(["lua", str(here / "surface_lifecycle_stress.lua.txt")], cwd=root,
                            capture_output=True, text=True, timeout=60)
    samples.append({"sample": index + 1, "exit": result.returncode,
                    "desktop_process_seconds": round(time.perf_counter() - began, 6),
                    "stdout": result.stdout, "stderr": result.stderr})
after = hashes()
report = {"captured_at_utc": datetime.now(timezone.utc).isoformat(),
          "status": "MOCK_INVARIANTS_PASSED" if all(s["exit"] == 0 for s in samples) and before == after else "FAILED_OR_DRIFTED",
          "scope": "Existing production-executing fixture extension; client labels do not introduce unmodeled client or instance semantics. Native taint/CPU/FPS/input/secure VM NOT RUN.",
          "mail_cycles_per_sample": 20000, "salvage_cycles_per_sample": 5000,
          "assertions_per_sample": 100000, "sources_before": before, "sources_after": after,
          "changed_sources": [p for p in sources if before[p] != after[p]], "samples": samples}
(here / "surface_lifecycle_results.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
print(json.dumps({k: report[k] for k in ("status", "changed_sources", "mail_cycles_per_sample", "salvage_cycles_per_sample", "assertions_per_sample")}, indent=2))
raise SystemExit(report["status"] != "MOCK_INVARIANTS_PASSED")
